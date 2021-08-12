# frozen_string_literal: true

class Geo::ContainerRepositoryRegistry < Geo::BaseRegistry
  include ::Delay

  MODEL_CLASS = ::ContainerRepository
  MODEL_FOREIGN_KEY = :container_repository_id

  belongs_to :container_repository

  scope :failed, -> { with_state(:failed) }
  scope :needs_sync_again, -> { failed.retry_due }
  scope :never_attempted_sync, -> { with_state(:pending).where(last_synced_at: nil) }
  scope :retry_due, -> { where(arel_table[:retry_at].eq(nil).or(arel_table[:retry_at].lt(Time.current))) }
  scope :synced, -> { with_state(:synced) }
  scope :sync_timed_out, -> { with_state(:started).where("last_synced_at < ?", Geo::ContainerRepositorySyncService::LEASE_TIMEOUT.ago) }

  state_machine :state, initial: :pending do
    state :started
    state :synced
    state :failed
    state :pending

    before_transition any => :started do |registry, _|
      registry.last_synced_at = Time.current
    end

    before_transition any => :pending do |registry, _|
      registry.retry_at    = 0
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
    include Delay

    def find_registries_needs_sync_again(batch_size:, except_ids: [])
      super.order(Gitlab::Database.nulls_first_order(:last_synced_at))
    end

    def delete_for_model_ids(container_repository_ids)
      where(container_repository_id: container_repository_ids).delete_all

      container_repository_ids
    end

    def pluck_container_repository_key
      where(nil).pluck(:container_repository_id)
    end

    def replication_enabled?
      Gitlab.config.geo.registry_replication.enabled
    end

    # Fail syncs for records which started syncing a long time ago
    def fail_sync_timeouts
      attrs = {
        state: :failed,
        last_sync_failure: "Sync timed out after #{Geo::ContainerRepositorySyncService::LEASE_TIMEOUT} hours",
        retry_count: 1,
        retry_at: next_retry_time(1)
      }

      sync_timed_out.all.each_batch do |relation|
        relation.update_all(attrs)
      end
    end
  end

  def fail_sync!(message, error)
    new_retry_count = retry_count + 1

    update!(
      state: :failed,
      last_sync_failure: "#{message}: #{error.message}",
      retry_count: new_retry_count,
      retry_at: next_retry_time(new_retry_count)
    )
  end

  def finish_sync!
    update!(
      retry_count: 0,
      last_sync_failure: nil,
      retry_at: nil
    )

    mark_synced_atomically
  end

  def mark_synced_atomically
    # We can only update registry if state is started.
    # If state is set to pending that means that repository_updated! was called
    # during the sync so we need to reschedule new sync
    num_rows = self.class
                   .where(container_repository_id: container_repository_id)
                   .where(state: 'started')
                   .update_all(state: 'synced')

    num_rows > 0
  end
end
