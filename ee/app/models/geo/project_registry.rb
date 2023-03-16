# frozen_string_literal: true

class Geo::ProjectRegistry < Geo::BaseRegistry
  include ::Delay
  include ::EachBatch
  include ::FromUnion
  include ::ShaAttribute

  MODEL_CLASS = ::Project
  MODEL_FOREIGN_KEY = :project_id

  REGISTRY_TYPES = %i{repository wiki}.freeze
  RETRIES_BEFORE_REDOWNLOAD = 10

  sha_attribute :repository_verification_checksum_sha
  sha_attribute :repository_verification_checksum_mismatched
  sha_attribute :wiki_verification_checksum_sha
  sha_attribute :wiki_verification_checksum_mismatched

  belongs_to :project

  validates :project, presence: true, uniqueness: true

  scope :dirty, -> { where(arel_table[:resync_repository].eq(true).or(arel_table[:resync_wiki].eq(true))) }
  scope :needs_sync_again, -> { dirty.retry_due }
  scope :never_attempted_sync, -> { where(last_repository_synced_at: nil) }
  scope :synced_repos, -> { where(resync_repository: false) }
  scope :synced_wikis, -> { where(resync_wiki: false) }
  scope :failed_repos, -> { where(arel_table[:repository_retry_count].gt(0)) }
  scope :failed_wikis, -> { where(arel_table[:wiki_retry_count].gt(0)) }
  scope :verified_repos, -> { where.not(repository_verification_checksum_sha: nil) }
  scope :verified_wikis, -> { where.not(wiki_verification_checksum_sha: nil) }
  scope :verification_failed_repos, -> { where.not(last_repository_verification_failure: nil) }
  scope :verification_failed_wikis, -> { where.not(last_wiki_verification_failure: nil) }
  scope :repository_checksum_mismatch, -> { where(repository_checksum_mismatch: true) }
  scope :wiki_checksum_mismatch, -> { where(wiki_checksum_mismatch: true) }
  scope :with_routes, -> { includes(project: :route).includes(project: { namespace: :route }) }

  class << self
    extend ::Gitlab::Utils::Override

    # TODO: Remove to make this resource available in the resync/reverify mutation
    # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/367926
    override :graphql_mutable?
    def graphql_mutable?
      false
    end
  end

  def self.project_id_in(ids)
    where(project_id: ids)
  end

  def self.pluck_project_key
    where(nil).pluck(:project_id)
  end

  def self.find_registries_needs_sync_again(batch_size:, except_ids: [])
    # TODO: Remove this as part of https://gitlab.com/gitlab-org/gitlab/-/issues/395807
    #
    # The Geo legacy implementation uses this method to find both project and
    # wiki repositories that need to sync again. But, we are migrating wiki
    # repositories  to the Geo SSF. So, we need to exclude wiki repositories
    # when the `geo_project_wiki_repository_replication` feature flag is
    # enabled.
    registries =
      if ::Geo::ProjectWikiRepositoryReplicator.enabled?
        where(resync_repository: true)
          .retry_due
          .model_id_not_in(except_ids)
          .limit(batch_size)
      else
        super
      end

    registries.order(arel_table[:last_repository_synced_at].asc.nulls_first)
  end

  def self.delete_worker_class
    ::GeoRepositoryDestroyWorker
  end

  def self.delete_for_model_ids(project_ids)
    project_ids.map do |project_id|
      delete_worker_class.perform_async(project_id)
    end
  end

  def self.failed
    repository_sync_failed = arel_table[:repository_retry_count].gt(0)
    wiki_sync_failed = arel_table[:wiki_retry_count].gt(0)

    where(repository_sync_failed.or(wiki_sync_failed))
  end

  def self.checksum_mismatch
    repository_checksum_mismatch = arel_table[:repository_checksum_mismatch].eq(true)
    wiki_checksum_mismatch = arel_table[:wiki_checksum_mismatch].eq(true)
    where(repository_checksum_mismatch.or(wiki_checksum_mismatch))
  end

  def self.repositories_retrying_verification
    where(
      arel_table[:repository_verification_retry_count].gt(0)
        .and(arel_table[:resync_repository].eq(true))
    )
  end

  def self.wikis_retrying_verification
    where(
      arel_table[:wiki_verification_retry_count].gt(0)
        .and(arel_table[:resync_wiki].eq(true))
    )
  end

  def self.retry_due
    where(
      arel_table[:repository_retry_at].lt(Time.current)
        .or(arel_table[:wiki_retry_at].lt(Time.current))
        .or(arel_table[:repository_retry_at].eq(nil))
        .or(arel_table[:wiki_retry_at].eq(nil))
    )
  end

  # Search for a list of projects associated with registries,
  # based on the query given in `query`.
  #
  # @param [String] query term that will search over :path, :name and :description
  def self.with_search(query)
    return all if query.empty?

    where(project_id: ::Project.search(query).limit(1000).pluck_primary_key)
  end

  def self.synced(type)
    case type
    when :repository
      synced_repos
    when :wiki
      synced_wikis
    else
      none
    end
  end

  def self.sync_failed(type)
    case type
    when :repository
      failed_repos
    when :wiki
      failed_wikis
    else
      failed
    end
  end

  def self.verified(type)
    case type
    when :repository
      verified_repos
    when :wiki
      verified_wikis
    else
      none
    end
  end

  def self.verification_failed(type)
    case type
    when :repository
      verification_failed_repos
    when :wiki
      verification_failed_wikis
    else
      verification_failed_repos.or(verification_failed_wikis)
    end
  end

  def self.retrying_verification(type)
    case type
    when :repository
      repositories_retrying_verification
    when :wiki
      wikis_retrying_verification
    else
      none
    end
  end

  def self.mismatch(type)
    case type
    when :repository
      repository_checksum_mismatch
    when :wiki
      wiki_checksum_mismatch
    else
      repository_checksum_mismatch.or(wiki_checksum_mismatch)
    end
  end

  def self.repositories_checksummed_pending_verification
    repository_exists_on_primary =
      Arel::Nodes::SqlLiteral.new('project_registry.repository_missing_on_primary IS NOT TRUE')

    where(repository_exists_on_primary)
      .where(last_repository_verification_failure: nil,
             primary_repository_checksummed: true,
             resync_repository: false,
             repository_verification_checksum_sha: nil)
  end

  def self.wikis_checksummed_pending_verification
    wiki_exists_on_primary =
      Arel::Nodes::SqlLiteral.new('project_registry.wiki_missing_on_primary IS NOT TRUE')

    where(wiki_exists_on_primary)
      .where(last_wiki_verification_failure: nil,
             primary_wiki_checksummed: true,
             resync_wiki: false,
             wiki_verification_checksum_sha: nil)
  end

  def self.flag_repositories_for_resync!
    update_all(
      resync_repository: true,
      repository_verification_checksum_sha: nil,
      repository_checksum_mismatch: false,
      last_repository_verification_failure: nil,
      repository_verification_retry_count: nil,
      resync_repository_was_scheduled_at: Time.current,
      repository_retry_count: nil,
      repository_retry_at: nil
    )
  end

  def self.flag_repositories_for_reverify!
    update_all(
      repository_verification_checksum_sha: nil,
      last_repository_verification_failure: nil,
      repository_checksum_mismatch: false
    )
  end

  # Retrieve the range of IDs in a relation
  #
  # @return [Array] with minimum ID and max ID
  def self.range
    pick('MIN(id)', 'MAX(id)')
  end

  # Search for IDs in the range
  #
  # @param [Integer] start initial ID
  # @param [Integer] finish final ID
  def self.with_range(start, finish)
    where(id: start..finish)
  end

  # @return [Boolean] whether the project repository is out-of-date on this site
  def self.repository_out_of_date?(project_id)
    return false unless ::Gitlab::Geo.secondary_with_primary?

    registry = find_by(project_id: project_id)

    # Out-of-date if registry or project don't exist
    return true if registry.nil? || registry.project.nil?

    # Up-to-date if there is no timestamp for the latest change to the repo
    return false unless registry.project.last_repository_updated_at

    # Out-of-date if the repo has never been synced
    return true unless registry.last_repository_successful_sync_at

    # Return whether the latest change is replicated
    #
    # Current limitations:
    #
    # - We assume last_repository_updated_at is a timestamp of the latest change
    # - last_repository_updated_at is also touched when a project wiki is updated
    # - last_repository_updated_at touches are throttled within Event::REPOSITORY_UPDATED_AT_INTERVAL minutes
    last_updated_at = registry.project.repository_state&.last_repository_updated_at
    last_updated_at ||= registry.project.last_repository_updated_at
    last_successful_sync = registry.last_repository_successful_sync_at

    last_successful_sync <= last_updated_at
  end

  # Must be run before fetching the repository to avoid a race condition
  #
  # @param [String] type must be one of the values in TYPES
  # @see REGISTRY_TYPES
  def start_sync!(type)
    ensure_valid_type!(type)

    update!(
      "last_#{type}_synced_at" => Time.current,
      "#{type}_retry_count" => retry_count(type))
  end

  # Is called when synchronization finishes without any issue
  #
  # @param [String] type must be one of the values in TYPES
  # @see REGISTRY_TYPES
  def finish_sync!(type, missing_on_primary = false, primary_checksummed = false)
    ensure_valid_type!(type)

    update!(
      # Indicate that the sync succeeded (but separately mark as synced atomically)
      "last_#{type}_successful_sync_at" => Time.current,
      "#{type}_retry_count" => nil,
      "#{type}_retry_at" => nil,
      "force_to_redownload_#{type}" => false,
      "last_#{type}_sync_failure" => nil,
      "#{type}_missing_on_primary" => missing_on_primary,

      # Indicate that repository verification needs to be done again
      "primary_#{type}_checksummed" => primary_checksummed,
      "#{type}_verification_checksum_sha" => nil,
      "#{type}_checksum_mismatch" => false,
      "last_#{type}_verification_failure" => nil)

    mark_synced_atomically(type)
  end

  # Is called when synchronization fails with an exception
  #
  # @param [String] type must be one of the values in TYPES
  # @param [String] message with a human readable description of the failure
  # @param [Exception] error the exception
  # @param [Hash] attrs attributes to update the database with
  # @see REGISTRY_TYPES
  def fail_sync!(type, message, error, attrs = {})
    ensure_valid_type!(type)

    new_retry_count = retry_count(type) + 1

    attrs["resync_#{type}"] = true
    attrs["last_#{type}_sync_failure"] = "#{message}: #{error.message}"
    attrs["#{type}_retry_count"] = new_retry_count
    attrs["#{type}_retry_at"] = next_retry_time(new_retry_count)

    update!(attrs)
  end

  def repository_created!(repository_created_event)
    update!(resync_repository: true,
            resync_wiki: repository_created_event.wiki_path.present?)
  end

  # Marks the project as dirty.
  #
  # resync_#{type}_was_scheduled_at tracks scheduled_at to avoid a race condition.
  # @see #mark_synced_atomically
  #
  # @param [String] type must be one of the values in TYPES
  # @param [Time] scheduled_at when it was scheduled
  # @see REGISTRY_TYPES
  def repository_updated!(type, scheduled_at)
    ensure_valid_type!(type)

    update!(
      "resync_#{type}" => true,
      "#{type}_verification_checksum_sha" => nil,
      "#{type}_checksum_mismatch" => false,
      "last_#{type}_verification_failure" => nil,
      "#{type}_verification_retry_count" => nil,
      "resync_#{type}_was_scheduled_at" => scheduled_at,
      "#{type}_retry_count" => nil,
      "#{type}_retry_at" => nil
    )
  end

  # Resets repository/wiki verification state. Is called when a Geo
  # secondary node process a Geo::ResetChecksumEvent.
  def reset_checksum!
    update!(
      primary_repository_checksummed: true,
      primary_wiki_checksummed: true,
      repository_verification_checksum_sha: nil,
      wiki_verification_checksum_sha: nil,
      repository_checksum_mismatch: false,
      wiki_checksum_mismatch: false,
      last_repository_verification_failure: nil,
      last_wiki_verification_failure: nil,
      repository_verification_retry_count: nil,
      wiki_verification_retry_count: nil
    )
  end

  def repository_sync_due?(scheduled_time)
    return true if last_repository_synced_at.nil?
    return false unless resync_repository?
    return false if repository_retry_at && scheduled_time < repository_retry_at

    scheduled_time > last_repository_synced_at
  end

  def wiki_sync_due?(scheduled_time)
    return true if last_wiki_synced_at.nil?
    return false unless resync_wiki?
    return false if wiki_retry_at && scheduled_time < wiki_retry_at

    scheduled_time > last_wiki_synced_at
  end

  # Returns whether repository is pending verification check
  #
  # This will check for missing verification checksum sha
  #
  # @return [Boolean] whether repository is pending verification
  def repository_verification_pending?
    self.repository_verification_checksum_sha.nil?
  end

  # Returns whether wiki is pending verification check
  #
  # This will check for missing verification checksum sha
  #
  # @return [Boolean] whether wiki is pending verification
  def wiki_verification_pending?
    self.wiki_verification_checksum_sha.nil?
  end

  # Returns whether verification is pending for either wiki or repository
  #
  # This will check for missing verification checksum sha for both wiki and repository
  #
  # @return [Boolean] whether verification is pending for either wiki or repository
  def pending_verification?
    repository_verification_pending? || wiki_verification_pending?
  end

  def pending_synchronization?
    resync_repository? || resync_wiki?
  end

  def syncs_since_gc
    Gitlab::Redis::SharedState.with { |redis| redis.get(fetches_since_gc_redis_key).to_i }
  end

  def increment_syncs_since_gc!
    Gitlab::Redis::SharedState.with { |redis| redis.incr(fetches_since_gc_redis_key) }
  end

  def reset_syncs_since_gc!
    Gitlab::Redis::SharedState.with { |redis| redis.del(fetches_since_gc_redis_key) }
  end

  def set_syncs_since_gc!(value)
    return false if !value.is_a?(Integer) || value < 0

    Gitlab::Redis::SharedState.with { |redis| redis.set(fetches_since_gc_redis_key, value) }
  end

  # Check if we should re-download *type*
  #
  # @param [String] type must be one of the values in TYPES
  # @see REGISTRY_TYPES
  def should_be_redownloaded?(type)
    ensure_valid_type!(type)
    return true if public_send("force_to_redownload_#{type}") # rubocop:disable GitlabSecurity/PublicSend

    retries = retry_count(type)

    retries > RETRIES_BEFORE_REDOWNLOAD && retries.odd?
  end

  def verification_retry_count(type)
    public_send("#{type}_verification_retry_count").to_i # rubocop:disable GitlabSecurity/PublicSend
  end

  # Flag the repository to be re-checked
  #
  # This operation happens only in the database and the reverify will be triggered after by the cron job
  def flag_repository_for_reverify!
    self.update(repository_verification_checksum_sha: nil, last_repository_verification_failure: nil, repository_checksum_mismatch: false)
  end

  # Flag the repository to be re-synced
  #
  # This operation happens only in the database and the resync will be triggered after by the cron job
  def flag_repository_for_resync!
    repository_updated!(:repository, Time.current)
  end

  # Flag the repository to perform a full re-download
  #
  # This operation happens only in the database and the forced re-download will be triggered after by the cron job
  def flag_repository_for_redownload!
    self.update(resync_repository: true, force_to_redownload_repository: true)
  end

  # A registry becomes candidate for re-download after first failed retries
  #
  # This is used by the Admin > Geo Nodes > Projects UI interface to choose
  # when to display the re-download button
  #
  # @return [Boolean] whether the registry is candidate for a re-download
  def candidate_for_redownload?
    return false if Feature.enabled?(:geo_deprecate_redownload)

    self.repository_retry_count && self.repository_retry_count > 1
  end

  # Returns a synchronization state based on existing attribute values
  #
  # It takes into account things like if a successful replication has been done
  # if there are pending actions or existing errors
  #
  # @return [Symbol] :never, :failed:, :pending or :synced
  def synchronization_state
    return :never if has_never_attempted_any_operation?
    return :failed if has_failed_operation?
    return :pending if has_pending_operation?

    :synced
  end

  def repository_has_successfully_synced?
    last_repository_successful_sync_at.present?
  end

  private

  # Whether any operation has ever been attempted
  #
  # This is intended to determine if it's a brand new registry that has never tried to sync before
  def has_never_attempted_any_operation?
    last_repository_successful_sync_at.nil? && last_repository_synced_at.nil?
  end

  # Whether there is a pending synchronization or verification
  #
  # This check is intended to be used as part of the #synchronization_state
  # It does omit previous checks as they are intended to be done in sequence.
  def has_pending_operation?
    resync_repository || repository_verification_checksum_sha.nil?
  end

  # Whether a synchronization or verification failed
  def has_failed_operation?
    repository_retry_count || last_repository_verification_failure || repository_checksum_mismatch
  end

  def fetches_since_gc_redis_key
    "projects/#{project_id}/fetches_since_gc"
  end

  # How many times have we retried syncing it?
  #
  # @param [String] type must be one of the values in TYPES
  # @see REGISTRY_TYPES
  def retry_count(type)
    public_send("#{type}_retry_count") || 0 # rubocop:disable GitlabSecurity/PublicSend
  end

  # Mark repository as synced using atomic conditions
  #
  # @return [Boolean] whether the update was successful
  # @param [String] type must be one of the values in TYPES
  # @see REGISTRY_TYPES
  def mark_synced_atomically(type)
    # Indicates whether the project is dirty (needs to be synced).
    #
    # This is the field we intend to reset to false.
    sync_column = "resync_#{type}"

    # The latest time that this project was marked as dirty.
    #
    # This field may change at any time when processing
    # `RepositoryUpdatedEvent`s.
    sync_scheduled_column = "resync_#{type}_was_scheduled_at"

    # The time recorded just before syncing.
    #
    # We know this field won't change between `start_sync!` and `finish_sync!`
    # because it is only updated by `start_sync!`, which is only done in the
    # exclusive lease block.
    sync_started_column = "last_#{type}_synced_at"

    # This conditional update must be atomic since RepositoryUpdatedEvent may
    # update resync_*_was_scheduled_at at any time.
    num_rows = self.class
                   .where(project: project)
                   .where("#{sync_scheduled_column} IS NULL OR #{sync_scheduled_column} < #{sync_started_column}")
                   .update_all(sync_column => false)

    num_rows > 0
  end

  # Make sure informed type is one of the allowed values
  #
  # @param [String] type must be one of the values in TYPES otherwise it will fail
  # @see REGISTRY_TYPES
  def ensure_valid_type!(type)
    raise ArgumentError, "Invalid type: '#{type.inspect}' informed. Must be one of the following: #{REGISTRY_TYPES.map { |type| "'#{type}'" }.join(', ')}" unless REGISTRY_TYPES.include?(type.to_sym)
  end
end
