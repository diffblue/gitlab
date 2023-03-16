# frozen_string_literal: true

module Geo
  module BlobReplicatorStrategy
    extend ActiveSupport::Concern

    include ::Geo::VerifiableReplicator
    include Gitlab::Geo::LogHelpers

    included do
      event :created
      event :deleted
    end

    class_methods do
      def sync_timeout
        ::Geo::BlobDownloadService::LEASE_TIMEOUT
      end

      def data_type
        'blob'
      end

      def data_type_title
        _('File')
      end

      def bulk_create_delete_events_async(deleted_records)
        return unless deleted_records.any?
        raise 'This method can only be called for a child class of Gitlab::Geo::Replicator' if replicable_name.nil?

        deleted_record_details = []

        events = deleted_records.map do |record|
          deleted_record_details << [replicable_name, record[:model_record_id], record[:blob_path]]

          raise 'model_record_id can not be nil' if record[:model_record_id].nil?

          {
            replicable_name: replicable_name,
            event_name: 'deleted',
            payload: {
              model_record_id: record[:model_record_id],
              blob_path: record[:blob_path],
              uploader_class: record[:uploader_class]
            },
            created_at: Time.current
          }
        end

        log_info('Bulk delete of: ', details: deleted_record_details)

        ::Geo::BatchEventCreateWorker.perform_async(events)
      end
    end

    def handle_after_create_commit
      return false unless Gitlab::Geo.primary?
      return unless self.class.enabled?

      publish(:created, **created_params)

      after_verifiable_update
    end

    # Called by Gitlab::Geo::Replicator#consume
    def consume_event_created(**params)
      resync
    end

    def resync
      return unless in_replicables_for_current_secondary?

      # Race condition mitigation for mutable types.
      #
      # Within a created event, we know that the source primary has changed. If a
      # sync is currently running, then *this* sync will be deduplicated (exit
      # early due to not being able to take the exclusive lease). In that case,
      # moving the registry to "pending" will block the currently running sync
      # from moving it to "synced". The running sync will then reschedule
      # itself to ensure a sync begins *after* the last known change to the
      # source primary. See `ReplicableRegistry#mark_synced_atomically`.
      #
      # We avoid saving when unpersisted since this should only occur if a
      # resource was just created but not yet replicated. And all saves after
      # the first one will raise the error `ActiveRecord::RecordNotUnique` anyway.
      registry.pending! if registry.persisted? && mutable?

      download
    end

    def enqueue_sync
      Geo::EventWorker.perform_async(replicable_name, 'created', { model_record_id: model_record.id })
    end

    # Called by Gitlab::Geo::Replicator#consume
    # Keep in mind that in_replicables_for_current_secondary? is not called here
    # This is because delete event should be handled by all the nodes
    # even if they're out of scope
    def consume_event_deleted(**params)
      replicate_destroy(params)
    end

    # Return the carrierwave uploader instance scoped to current model
    #
    # @abstract
    # @return [Carrierwave::Uploader]
    def carrierwave_uploader
      raise NotImplementedError
    end

    # Return the absolute path to locally stored file
    #
    # @return [String] File path
    def blob_path
      carrierwave_uploader.path
    end

    def replicate_destroy(event_data)
      ::Geo::FileRegistryRemovalService.new(
        replicable_name,
        model_record_id,
        removed_blob_path(event_data[:uploader_class], event_data[:blob_path]),
        event_data[:uploader_class]
      ).execute
    end

    def removed_blob_path(uploader_class, path)
      return unless path.present?
      # Backward compatibility check. Remove in 15.x
      return path if uploader_class.nil?

      File.join(uploader_class.constantize.root, path)
    end

    # Returns a checksum of the file
    #
    # @return [String] SHA256 hash of the carrierwave file
    def calculate_checksum
      raise 'File is not checksummable' unless checksummable?

      model.sha256_hexdigest(blob_path)
    end

    # Returns whether the file exists on disk or in remote storage
    #
    # Does a hard check because we are doing these checks for replication or
    # verification purposes, so we should not just trust the data in the DB if
    # we don't absolutely have to.
    #
    # @return [Boolean] whether the file exists on disk or in remote storage
    def file_exists?
      carrierwave_uploader.file&.exists?
    end

    def deleted_params
      {
        model_record_id: model_record_id,
        uploader_class: carrierwave_uploader.class.to_s,
        blob_path: carrierwave_uploader.relative_path
      }
    end

    private

    def download
      ::Geo::BlobDownloadService.new(replicator: self).execute
    end

    # Return whether it's capable of generating a checksum of itself
    #
    # @return [Boolean] whether it can generate a checksum
    def checksummable?
      carrierwave_uploader.file_storage? && file_exists?
    end

    # Return whether it's immutable
    #
    # @return [Boolean] whether the replicable is immutable
    def immutable?
      # Most blobs are supposed to be immutable.
      # Override this in your specific Replicator class if needed.
      true
    end

    def mutable?
      !immutable?
    end
  end
end
