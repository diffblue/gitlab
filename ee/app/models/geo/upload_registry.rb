# frozen_string_literal: true

class Geo::UploadRegistry < Geo::BaseRegistry
  include ::Geo::ReplicableRegistry

  extend ::Gitlab::Utils::Override

  MODEL_CLASS = ::Upload
  MODEL_FOREIGN_KEY = :file_id

  self.table_name = 'file_registry'

  belongs_to :upload, foreign_key: :file_id

  scope :fresh, -> { order(created_at: :desc) }

  def self.find_registry_differences(range)
    source =
      self::MODEL_CLASS.replicables_for_current_secondary(range)
          .pluck(self::MODEL_CLASS.arel_table[:id])

    tracked =
      self.model_id_in(range)
          .pluck(:file_id)

    untracked = source - tracked
    unused_tracked = tracked - source

    [untracked, unused_tracked]
  end

  # If false, RegistryConsistencyService will frequently check the end of the
  # table to quickly handle new replicables.
  def self.has_create_events?
    ::Geo::UploadReplicator.enabled?
  end

  def self.insert_for_model_ids(attrs)
    records = attrs.map do |file_id|
      new(file_id: file_id, created_at: Time.zone.now)
    end

    bulk_insert!(records, returns: :ids)
  end

  def self.delete_for_model_ids(attrs)
    attrs.map do |file_id|
      delete_worker_class.perform_async(:upload, file_id)
    end
  end

  def self.delete_worker_class
    ::Geo::FileRegistryRemovalWorker
  end

  def self.with_search(query)
    return all if query.nil?

    where(file_id: Upload.search(query).limit(1000).pluck_primary_key)
  end

  def self.with_status(status)
    case status
    when 'synced', 'failed'
      self.public_send(status) # rubocop: disable GitlabSecurity/PublicSend
    when 'pending'
      never_attempted_sync
    else
      all
    end
  end

  def file
    upload&.path || s_('Removed upload with id %{id}') % { id: file_id }
  end

  def project
    return upload.model if upload&.model.is_a?(Project)
  end
end
