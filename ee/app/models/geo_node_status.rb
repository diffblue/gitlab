# frozen_string_literal: true

class GeoNodeStatus < ApplicationRecord
  include ShaAttribute

  belongs_to :geo_node

  delegate :selective_sync_type, to: :geo_node

  after_initialize :initialize_feature_flags
  before_save :coerce_status_field_values, if: :status_changed?

  attr_accessor :storage_shards

  # Prometheus metrics, no need to store them in the database
  attr_accessor :event_log_max_id, :repository_created_max_id, :repository_updated_max_id,
                :repository_deleted_max_id, :repository_renamed_max_id, :repositories_changed_max_id,
                :lfs_objects_registry_count, :job_artifacts_registry_count,
                :hashed_storage_migrated_max_id, :hashed_storage_attachments_max_id,
                :repositories_checked_count, :repositories_checked_failed_count

  sha_attribute :storage_configuration_digest

  alias_attribute :repositories_count, :projects_count
  alias_attribute :wikis_count, :projects_count

  attribute_method_suffix '_timestamp', '_timestamp='

  alias_attribute :last_successful_status_check_timestamp, :last_successful_status_check_at_timestamp
  alias_attribute :last_event_timestamp, :last_event_date_timestamp
  alias_attribute :cursor_last_event_timestamp, :cursor_last_event_date_timestamp

  scope :for_active_secondaries, -> { joins(:geo_node).merge(GeoNode.secondary_nodes.where(enabled: true)) }

  def self.status_fields_for(replicable_class)
    {
      "#{replicable_class.replicable_name_plural}_count".to_sym => "Number of #{replicable_class.replicable_title_plural} on the primary",
      "#{replicable_class.replicable_name_plural}_checksum_total_count".to_sym => "Number of #{replicable_class.replicable_title_plural} available to checksum on primary",
      "#{replicable_class.replicable_name_plural}_checksummed_count".to_sym => "Number of #{replicable_class.replicable_title_plural} checksummed on the primary",
      "#{replicable_class.replicable_name_plural}_checksum_failed_count".to_sym => "Number of #{replicable_class.replicable_title_plural} failed to checksum on primary",
      "#{replicable_class.replicable_name_plural}_synced_count".to_sym => "Number of #{replicable_class.replicable_title_plural} in the registry",
      "#{replicable_class.replicable_name_plural}_failed_count".to_sym => "Number of #{replicable_class.replicable_title_plural} failed on secondary",
      "#{replicable_class.replicable_name_plural}_registry_count".to_sym => "Number of #{replicable_class.replicable_title_plural} synced to sync on secondary",
      "#{replicable_class.replicable_name_plural}_verification_total_count".to_sym => "Number of #{replicable_class.replicable_title_plural} available to verify on secondary",
      "#{replicable_class.replicable_name_plural}_verified_count".to_sym => "Number of #{replicable_class.replicable_title_plural} verified on the secondary",
      "#{replicable_class.replicable_name_plural}_verification_failed_count".to_sym => "Number of #{replicable_class.replicable_title_plural} failed to verify on secondary"
    }
  end

  # Why are disabled classes included? See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/38959#note_402656534
  def self.replicator_class_status_fields
    Gitlab::Geo::REPLICATOR_CLASSES.map do |replicable_class|
      status_fields_for(replicable_class).keys
    end.flatten.map(&:to_s)
  end

  def self.usage_data_fields
    Geo::SecondaryUsageData::PAYLOAD_COUNT_FIELDS
  end

  RESOURCE_STATUS_FIELDS = (%w(
    repository_verification_enabled
    repositories_replication_enabled
    repositories_synced_count
    repositories_failed_count
    wikis_synced_count
    wikis_failed_count
    repositories_verified_count
    repositories_verification_failed_count
    repositories_verification_total_count
    wikis_verified_count
    wikis_verification_failed_count
    wikis_verification_total_count
    job_artifacts_synced_missing_on_primary_count
    repositories_checksummed_count
    repositories_checksum_failed_count
    repositories_checksum_mismatch_count
    repositories_checksum_total_count
    wikis_checksummed_count
    wikis_checksum_failed_count
    wikis_checksum_mismatch_count
    wikis_checksum_total_count
    repositories_retrying_verification_count
    wikis_retrying_verification_count
    projects_count
    container_repositories_replication_enabled
    design_repositories_replication_enabled
    design_repositories_count
    design_repositories_synced_count
    design_repositories_failed_count
  ) + replicator_class_status_fields + usage_data_fields).freeze

  # Why are disabled classes included? See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/38959#note_402656534
  def self.replicator_class_prometheus_metrics
    Gitlab::Geo::REPLICATOR_CLASSES.map do |replicable_class|
      status_fields_for(replicable_class)
    end.reduce({}, :merge)
  end

  # Be sure to keep this consistent with Prometheus naming conventions
  PROMETHEUS_METRICS = {
    db_replication_lag_seconds: 'Database replication lag (seconds)',
    repository_verification_enabled: 'Boolean denoting if verification is enabled for Repositories',
    repositories_replication_enabled: 'Boolean denoting if replication is enabled for Repositories',
    repositories_count: 'Total number of repositories available on primary',
    repositories_synced_count: 'Number of repositories synced on secondary',
    repositories_failed_count: 'Number of repositories failed to sync on secondary',
    wikis_synced_count: 'Number of wikis synced on secondary',
    wikis_failed_count: 'Number of wikis failed to sync on secondary',
    repositories_checksummed_count: 'Number of repositories checksummed on primary',
    repositories_checksum_failed_count: 'Number of repositories failed to calculate the checksum on primary',
    wikis_checksummed_count: 'Number of wikis checksummed on primary',
    wikis_checksum_failed_count: 'Number of wikis failed to calculate the checksum on primary',
    repositories_verified_count: 'Number of repositories verified on secondary',
    repositories_verification_failed_count: 'Number of repositories failed to verify on secondary',
    repositories_checksum_mismatch_count: 'Number of repositories that checksum mismatch on secondary',
    wikis_verified_count: 'Number of wikis verified on secondary',
    wikis_verification_failed_count: 'Number of wikis failed to verify on secondary',
    wikis_checksum_mismatch_count: 'Number of wikis that checksum mismatch on secondary',
    job_artifacts_synced_missing_on_primary_count: 'Number of job artifacts marked as synced due to the file missing on the primary',
    replication_slots_count: 'Total number of replication slots on the primary',
    replication_slots_used_count: 'Number of replication slots in use on the primary',
    replication_slots_max_retained_wal_bytes: 'Maximum number of bytes retained in the WAL on the primary',
    last_event_id: 'Database ID of the latest event log entry on the primary',
    last_event_timestamp: 'Time of the latest event log entry on the primary',
    cursor_last_event_id: 'Last database ID of the event log processed by the secondary',
    cursor_last_event_timestamp: 'Time of the event log processed by the secondary',
    last_successful_status_check_timestamp: 'Time when Geo node status was updated internally',
    status_message: 'Summary of health status',
    event_log_max_id: 'Highest ID present in the Geo event log',
    repository_created_max_id: 'Highest ID present in repositories created',
    repository_updated_max_id: 'Highest ID present in repositories updated',
    repository_deleted_max_id: 'Highest ID present in repositories deleted',
    repository_renamed_max_id: 'Highest ID present in repositories renamed',
    repositories_changed_max_id: 'Highest ID present in repositories changed',
    hashed_storage_migrated_max_id: 'Highest ID present in projects migrated to hashed storage',
    hashed_storage_attachments_max_id: 'Highest ID present in attachments migrated to hashed storage',
    repositories_checked_count: 'Number of repositories checked',
    repositories_checked_failed_count: 'Number of failed repositories checked',
    repositories_retrying_verification_count: 'Number of repositories verification failures that Geo is actively trying to correct on secondary',
    wikis_retrying_verification_count: 'Number of wikis verification failures that Geo is actively trying to correct on secondary',
    container_repositories_replication_enabled: 'Boolean denoting if replication is enabled for Container Repositories',
    design_repositories_replication_enabled: 'Boolean denoting if replication is enabled for Design Repositories',
    design_repositories_count: 'Total number of syncable design repositories available on primary',
    design_repositories_synced_count: 'Number of syncable design repositories synced on secondary',
    design_repositories_failed_count: 'Number of syncable design repositories failed to sync on secondary',
    design_repositories_registry_count: 'Number of design repositories in the registry'
  }.merge(replicator_class_prometheus_metrics).freeze

  EXPIRATION_IN_MINUTES = 10
  HEALTHY_STATUS = 'Healthy'
  UNHEALTHY_STATUS = 'Unhealthy'

  def self.alternative_status_store_accessor(attr_names)
    attr_names.each do |attr_name|
      define_method(attr_name) do
        val = status[attr_name]

        # Backwards-compatible line for when the status was written by an
        # earlier release without the `status` field
        val ||= read_attribute(attr_name)

        convert_status_value(attr_name, val)
      end

      define_method("#{attr_name}=") do |val|
        val = convert_status_value(attr_name, val)

        status[attr_name] = val
      end
    end
  end

  alternative_status_store_accessor RESOURCE_STATUS_FIELDS

  def self.current_node_status
    current_node = Gitlab::Geo.current_node
    return unless current_node

    status = current_node.find_or_build_status

    status.load_data_from_current_node

    status.save if Gitlab::Geo.primary?

    status
  end

  def self.fast_current_node_status
    attrs = Rails.cache.read(cache_key)

    if attrs
      new(attrs)
    else
      spawn_worker
      nil
    end
  end

  def self.spawn_worker
    ::Geo::MetricsUpdateWorker.perform_async # rubocop:disable CodeReuse/Worker
  end

  def self.cache_key
    "geo-node:#{Gitlab::Geo.current_node.id}:status"
  end

  def self.from_json(json_data)
    json_data.slice!(*allowed_params)

    GeoNodeStatus.new(HashWithIndifferentAccess.new(json_data))
  end

  EXCLUDED_PARAMS = %w[id created_at].freeze
  EXTRA_PARAMS = %w[
    last_event_timestamp
    cursor_last_event_timestamp
    storage_shards
  ].freeze

  def self.allowed_params
    self.column_names - EXCLUDED_PARAMS + EXTRA_PARAMS
  end

  # Helps make alternative_status_store_accessor act more like regular Rails
  # attributes. Request params values are always strings, but when saved as
  # attributes of a model, they are converted to the appropriate types. We could
  # manually map a specified type to each attribute, but for now, the type can
  # be easily inferred by the attribute name.
  #
  # If you add a new status attribute that does not look like existing
  # attributes, then you'll get an error until you handle it in the cases below.
  #
  # @param [String] attr_name the status key
  # @param [String, Integer, Boolean] val being assigned or retrieved
  # @return [String, Integer, Boolean] converted value based on attr_name
  def convert_status_value(attr_name, val)
    return if val.nil?

    case attr_name
    when /_count(?:_weekly)?\z/ then val.to_i
    when /_enabled\z/ then val.to_s == 'true'
    else raise "Unhandled status attribute name format \"#{attr_name}\""
    end
  end

  # Leverages attribute reader methods written by
  # alternative_status_store_accessor to convert string values to integers and
  # booleans if necessary.
  def coerce_status_field_values
    status_attrs = status.slice(*RESOURCE_STATUS_FIELDS)
    self.assign_attributes(status_attrs)
  end

  def initialize_feature_flags
    self.repository_verification_enabled = Gitlab::Geo.repository_verification_enabled?

    if Gitlab::Geo.secondary?
      self.container_repositories_replication_enabled = Geo::ContainerRepositoryRegistry.replication_enabled?
      self.design_repositories_replication_enabled = Geo::DesignRegistry.replication_enabled?
      self.repositories_replication_enabled = Geo::ProjectRegistry.replication_enabled?
    end
  end

  def update_cache!
    Rails.cache.write(self.class.cache_key, attributes)
  end

  def load_data_from_current_node
    latest_event = Geo::EventLog.latest_event
    self.last_event_id = latest_event&.id
    self.last_event_date = latest_event&.created_at
    self.last_successful_status_check_at = Time.current

    self.storage_shards = StorageShard.all
    self.storage_configuration_digest = StorageShard.build_digest

    self.version = Gitlab::VERSION
    self.revision = Gitlab.revision

    load_status_message
    load_event_data
    load_primary_data
    load_secondary_data
    load_repository_check_data
    load_verification_data
  end

  def current_cursor_last_event_id
    return unless Gitlab::Geo.secondary?

    min_gap_id = ::Gitlab::Geo::EventGapTracking.min_gap_id
    last_processed_id = Geo::EventLogState.last_processed&.event_id

    [min_gap_id, last_processed_id].compact.min
  end

  def healthy?
    !outdated? && status_message_healthy?
  end

  def health
    status_message
  end

  def health_status
    healthy? ? HEALTHY_STATUS : UNHEALTHY_STATUS
  end

  def outdated?
    return false unless updated_at

    updated_at < EXPIRATION_IN_MINUTES.minutes.ago
  end

  def status_message_healthy?
    status_message.blank? || status_message == HEALTHY_STATUS
  end

  def attribute_timestamp(attr)
    self[attr].to_i
  end

  def attribute_timestamp=(attr, value)
    self[attr] = Time.zone.at(value)
  end

  def self.percentage_methods
    @percentage_methods || []
  end

  def self.attr_in_percentage(attr_name, count, total)
    method_name = "#{attr_name}_in_percentage"
    @percentage_methods ||= []
    @percentage_methods << method_name

    define_method(method_name) do
      return 0 if self[total].to_i == 0

      (self[count].to_f / self[total].to_f) * 100.0
    end
  end

  def self.add_attr_in_percentage_for_replicable_classes
    Gitlab::Geo::REPLICATOR_CLASSES.each do |replicator|
      replicable = replicator.replicable_name_plural
      attr_in_percentage "#{replicable}_synced",       "#{replicable}_synced_count",       "#{replicable}_registry_count"
      attr_in_percentage "#{replicable}_verified",     "#{replicable}_verified_count",     "#{replicable}_registry_count"
    end
  end

  attr_in_percentage :repositories_synced,           :repositories_synced_count,           :repositories_count
  attr_in_percentage :repositories_checksummed,      :repositories_checksummed_count,      :repositories_count
  attr_in_percentage :repositories_verified,         :repositories_verified_count,         :repositories_count
  attr_in_percentage :repositories_checked,          :repositories_checked_count,          :repositories_count
  attr_in_percentage :wikis_synced,                  :wikis_synced_count,                  :wikis_count
  attr_in_percentage :wikis_checksummed,             :wikis_checksummed_count,             :wikis_count
  attr_in_percentage :wikis_verified,                :wikis_verified_count,                :wikis_count
  attr_in_percentage :replication_slots_used,        :replication_slots_used_count,        :replication_slots_count
  attr_in_percentage :design_repositories_synced,    :design_repositories_synced_count,    :design_repositories_count

  add_attr_in_percentage_for_replicable_classes

  def synced_in_percentage_for(replicator_class)
    public_send("#{replicator_class.replicable_name_plural}_synced_in_percentage") # rubocop:disable GitlabSecurity/PublicSend
  end

  def verified_in_percentage_for(replicator_class)
    public_send("#{replicator_class.replicable_name_plural}_verified_in_percentage") # rubocop:disable GitlabSecurity/PublicSend
  end

  def count_for(replicator_class)
    public_send("#{replicator_class.replicable_name_plural}_count") # rubocop:disable GitlabSecurity/PublicSend
  end

  def storage_shards_match?
    return true if geo_node.primary?
    return false unless storage_configuration_digest && primary_storage_digest

    storage_configuration_digest == primary_storage_digest
  end

  def [](key)
    public_send(key) # rubocop:disable GitlabSecurity/PublicSend
  end

  private

  def load_status_message
    self.status_message =
      begin
        HealthCheck::Utils.process_checks(['geo'])
      rescue NotImplementedError => e
        e.to_s
      end
  end

  def load_event_data
    self.event_log_max_id = Geo::EventLog.maximum(:id)
    self.repository_created_max_id = Geo::RepositoryCreatedEvent.maximum(:id)
    self.repository_updated_max_id = Geo::RepositoryUpdatedEvent.maximum(:id)
    self.repository_deleted_max_id = Geo::RepositoryDeletedEvent.maximum(:id)
    self.repository_renamed_max_id = Geo::RepositoryRenamedEvent.maximum(:id)
    self.repositories_changed_max_id = Geo::RepositoriesChangedEvent.maximum(:id)
    self.hashed_storage_migrated_max_id = Geo::HashedStorageMigratedEvent.maximum(:id)
    self.hashed_storage_attachments_max_id = Geo::HashedStorageAttachmentsEvent.maximum(:id)
  end

  def load_primary_data
    return unless Gitlab::Geo.primary?

    self.projects_count = geo_node.projects.count
    self.replication_slots_count = geo_node.replication_slots_count
    self.replication_slots_used_count = geo_node.replication_slots_used_count
    self.replication_slots_max_retained_wal_bytes = geo_node.replication_slots_max_retained_wal_bytes

    Gitlab::Geo::REPLICATOR_CLASSES.each do |replicator|
      public_send("#{replicator.replicable_name_plural}_count=", replicator.primary_total_count) # rubocop:disable GitlabSecurity/PublicSend
    end
  end

  def load_secondary_data
    return unless Gitlab::Geo.secondary?

    self.db_replication_lag_seconds = Gitlab::Geo::HealthCheck.new.db_replication_lag_seconds
    self.cursor_last_event_id = current_cursor_last_event_id
    self.cursor_last_event_date = Geo::EventLog.find_by(id: self.cursor_last_event_id)&.created_at

    load_repositories_data
    load_designs_data
    load_ssf_replicable_data
    load_secondary_usage_data
  end

  def load_repositories_data
    self.projects_count = Geo::ProjectRegistry.count
    self.repositories_synced_count = Geo::ProjectRegistry.synced(:repository).count
    self.repositories_failed_count = Geo::ProjectRegistry.sync_failed(:repository).count
    self.wikis_synced_count = Geo::ProjectRegistry.synced(:wiki).count
    self.wikis_failed_count = Geo::ProjectRegistry.sync_failed(:wiki).count
  end

  def load_designs_data
    return unless design_repositories_replication_enabled

    self.design_repositories_count = design_registry_finder.registry_count
    self.design_repositories_synced_count = design_registry_finder.synced_count
    self.design_repositories_failed_count = design_registry_finder.failed_count
    self.design_repositories_registry_count = design_registry_finder.registry_count
  end

  def load_ssf_replicable_data
    Gitlab::Geo.enabled_replicator_classes.each do |replicator|
      public_send("#{replicator.replicable_name_plural}_count=", replicator.registry_count) # rubocop:disable GitlabSecurity/PublicSend
      public_send("#{replicator.replicable_name_plural}_registry_count=", replicator.registry_count) # rubocop:disable GitlabSecurity/PublicSend
      public_send("#{replicator.replicable_name_plural}_synced_count=", replicator.synced_count) # rubocop:disable GitlabSecurity/PublicSend
      public_send("#{replicator.replicable_name_plural}_failed_count=", replicator.failed_count) # rubocop:disable GitlabSecurity/PublicSend
    end
  end

  def load_secondary_usage_data
    usage_data = Geo::SecondaryUsageData.last
    return unless usage_data

    self.class.usage_data_fields.each do |field|
      status[field] = usage_data.payload[field]
    end
  end

  def load_repository_check_data
    if Gitlab::Geo.primary?
      self.repositories_checked_count = Project.where.not(last_repository_check_at: nil).count
      self.repositories_checked_failed_count = Project.where(last_repository_check_failed: true).count
    elsif Gitlab::Geo.secondary?
      self.repositories_checked_count = Geo::ProjectRegistry.where.not(last_repository_check_at: nil).count
      self.repositories_checked_failed_count = Geo::ProjectRegistry.where(last_repository_check_failed: true).count
    end
  end

  def load_verification_data
    return unless repository_verification_enabled

    if Gitlab::Geo.primary?
      load_primary_verification_data
    elsif Gitlab::Geo.secondary?
      load_secondary_verification_data
    end
  end

  def load_primary_verification_data
    self.repositories_checksummed_count = repository_verification_finder.count_verified_repositories
    self.repositories_checksum_failed_count = repository_verification_finder.count_verification_failed_repositories
    self.repositories_checksum_total_count = self.projects_count
    self.wikis_checksummed_count = repository_verification_finder.count_verified_wikis
    self.wikis_checksum_failed_count = repository_verification_finder.count_verification_failed_wikis
    self.wikis_checksum_total_count = self.projects_count

    Gitlab::Geo::REPLICATOR_CLASSES.each do |replicator|
      next unless replicator.verification_feature_flag_enabled?

      public_send("#{replicator.replicable_name_plural}_checksummed_count=", replicator.checksummed_count) # rubocop:disable GitlabSecurity/PublicSend
      public_send("#{replicator.replicable_name_plural}_checksum_failed_count=", replicator.checksum_failed_count) # rubocop:disable GitlabSecurity/PublicSend
      public_send("#{replicator.replicable_name_plural}_checksum_total_count=", replicator.checksum_total_count) # rubocop:disable GitlabSecurity/PublicSend
    end
  end

  def load_secondary_verification_data
    self.repositories_verified_count = Geo::ProjectRegistry.verified(:repository).count
    self.repositories_verification_failed_count = Geo::ProjectRegistry.verification_failed(:repository).count
    self.repositories_verification_total_count = self.projects_count
    self.repositories_checksum_mismatch_count = Geo::ProjectRegistry.mismatch(:repository).count
    self.wikis_verified_count = Geo::ProjectRegistry.verified(:wiki).count
    self.wikis_verification_failed_count = Geo::ProjectRegistry.verification_failed(:wiki).count
    self.wikis_verification_total_count = self.projects_count
    self.wikis_checksum_mismatch_count = Geo::ProjectRegistry.mismatch(:wiki).count
    self.repositories_retrying_verification_count = Geo::ProjectRegistry.retrying_verification(:repository).count
    self.wikis_retrying_verification_count = Geo::ProjectRegistry.retrying_verification(:wiki).count

    ::Gitlab::Geo.verification_enabled_replicator_classes.each do |replicator|
      public_send("#{replicator.replicable_name_plural}_verified_count=", replicator.verified_count) # rubocop:disable GitlabSecurity/PublicSend
      public_send("#{replicator.replicable_name_plural}_verification_failed_count=", replicator.verification_failed_count) # rubocop:disable GitlabSecurity/PublicSend
      public_send("#{replicator.replicable_name_plural}_verification_total_count=", replicator.verification_total_count) # rubocop:disable GitlabSecurity/PublicSend
    end
  end

  def primary_storage_digest
    @primary_storage_digest ||= Gitlab::Geo.primary_node.find_or_build_status.storage_configuration_digest
  end

  def design_registry_finder
    @design_registry_finder ||= Geo::DesignRegistryFinder.new
  end

  def repository_verification_finder
    @repository_verification_finder ||= Geo::RepositoryVerificationFinder.new
  end
end
