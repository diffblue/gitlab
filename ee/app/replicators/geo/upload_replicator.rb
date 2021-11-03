# frozen_string_literal: true

module Geo
  class UploadReplicator < Gitlab::Geo::Replicator
    include ::Geo::BlobReplicatorStrategy
    extend ::Gitlab::Utils::Override

    def self.model
      ::Upload
    end

    def self.bulk_create_delete_events_async(deleted_uploads)
      return if deleted_uploads.empty?

      deleted_upload_details = []

      events = deleted_uploads.map do |upload|
        deleted_upload_details << [upload[:model_record_id], upload[:blob_path]]

        {
          replicable_name: 'upload',
          event_name: 'deleted',
          payload: {
            model_record_id: upload[:model_record_id],
            blob_path: upload[:blob_path],
            uploader_class: upload[:uploader_class]
          },
          created_at: Time.current
        }
      end

      log_info('Delete bulk of uploads: ', uploads: deleted_upload_details)

      ::Geo::BatchEventCreateWorker.perform_async(events)
    end

    def carrierwave_uploader
      model_record.retrieve_uploader
    end

    # TODO: This method can be removed as part of
    # https://gitlab.com/gitlab-org/gitlab/-/issues/340617
    override :registry
    def registry
      super.tap do |record|
        # We don't really need this value for SSF, it's only needed to make
        # new registry records valid for legacy code in case of disabling the feature.
        record.file_type ||= model_record.uploader.delete_suffix("Uploader").underscore
      end
    end
  end
end
