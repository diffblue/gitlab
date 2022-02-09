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
    end

    def handle_after_create_commit
      return false unless Gitlab::Geo.primary?
      return unless self.class.enabled?

      publish(:created, **created_params)

      after_verifiable_update
    end

    # Called by Gitlab::Geo::Replicator#consume
    def consume_event_created(**params)
      return unless in_replicables_for_current_secondary?

      download
    end

    # Called by Gitlab::Geo::Replicator#consume
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
        removed_blob_path(event_data[:uploader_class], event_data[:blob_path])
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
        model_record_id: model_record.id,
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
  end
end
