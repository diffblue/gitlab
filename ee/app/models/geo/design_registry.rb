# frozen_string_literal: true

class Geo::DesignRegistry < Geo::BaseRegistry
  include ::Delay

  MODEL_CLASS = ::Project
  MODEL_FOREIGN_KEY = :project_id

  RETRIES_BEFORE_REDOWNLOAD = 10

  belongs_to :project

  scope :dirty, -> { with_state(:pending).where.not(last_synced_at: nil) }
  scope :failed, -> { with_state(:failed) }
  scope :needs_sync_again, -> { dirty.or(failed.retry_due) }
  scope :never_attempted_sync, -> { with_state(:pending).where(last_synced_at: nil) }
  scope :retry_due, -> { where(arel_table[:retry_at].eq(nil).or(arel_table[:retry_at].lt(Time.current))) }
  scope :synced, -> { with_state(:synced) }

  state_machine :state, initial: :pending do
    state :started
    state :synced
    state :failed
    state :pending

    before_transition any => :started do |registry, _|
      registry.last_synced_at = Time.current
    end

    before_transition any => :pending do |registry, _|
      registry.retry_at    = nil
      registry.retry_count = 0
    end

    event :start_sync! do
      transition [:synced, :failed, :pending] => :started
    end

    event :repository_updated! do
      transition [:synced, :failed, :started] => :pending
    end
  end

  class << self
    extend ::Gitlab::Utils::Override

    # TODO: Remove to make this resource available in the resync/reverify mutation
    # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/391189
    override :graphql_mutable?
    def graphql_mutable?
      false
    end
  end

  def self.delete_for_model_ids(project_ids)
    # We only need to delete the registry entries here. The design
    # repository deletion should happen when a project is destroyed.
    #
    # See: https://gitlab.com/gitlab-org/gitlab/-/issues/13429
    where(project_id: project_ids).delete_all

    project_ids
  end

  def self.find_registry_differences(range)
    source_ids = Gitlab::Geo.current_node.designs.id_in(range).pluck_primary_key
    tracked_ids = self.pluck_model_ids_in_range(range)

    untracked_ids = source_ids - tracked_ids
    unused_tracked_ids = tracked_ids - source_ids

    [untracked_ids, unused_tracked_ids]
  end

  def self.find_registries_needs_sync_again(batch_size:, except_ids: [])
    super.order(arel_table[:last_synced_at].asc.nulls_first)
  end

  # Search for a list of projects associated with registries,
  # based on the query given in `query`.
  #
  # @param [String] query term that will search over :path, :name and :description
  def self.with_search_by_project(query)
    return all if query.empty?

    where(project_id: ::Project.search(query).limit(1000).pluck_primary_key)
  end

  def self.search(params)
    designs_repositories = self
    designs_repositories = designs_repositories.with_state(params[:sync_status]) if params[:sync_status].present?
    designs_repositories = designs_repositories.with_search_by_project(params[:search]) if params[:search].present?
    designs_repositories
  end

  def fail_sync!(message, error, attrs = {})
    new_retry_count = retry_count + 1

    attrs[:state] = :failed
    attrs[:last_sync_failure] = "#{message}: #{error.message}"
    attrs[:retry_count] = new_retry_count
    attrs[:retry_at] = next_retry_time(new_retry_count)

    update!(attrs)
  end

  def finish_sync!(missing_on_primary = false)
    update!(
      missing_on_primary: missing_on_primary,
      retry_count: 0,
      last_sync_failure: nil,
      retry_at: nil,
      force_to_redownload: false
    )

    mark_synced_atomically
  end

  def mark_synced_atomically
    # We can only update registry if state is started.
    # If state is set to pending that means that repository_updated! was called
    # during the sync so we need to reschedule new sync
    num_rows = self.class
                   .where(project_id: project_id)
                   .where(state: 'started')
                   .update_all(state: 'synced')

    num_rows > 0
  end

  def should_be_redownloaded?
    return true if force_to_redownload

    retry_count.present? && retry_count > RETRIES_BEFORE_REDOWNLOAD && retry_count.odd?
  end
end
