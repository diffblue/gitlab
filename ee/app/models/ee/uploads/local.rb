# frozen_string_literal: true

module EE
  module Uploads
    module Local
      extend ::Gitlab::Utils::Override

      override :keys
      def keys(relation)
        return super unless ::Geo::EventStore.can_create_event?

        relation.includes(:model).find_each.map do |record|
          record.replicator.deleted_params.merge(absolute_path: record.absolute_path)
        end
      end

      override :delete_keys_async
      def delete_keys_async(keys_to_delete)
        return super unless ::Geo::EventStore.can_create_event?

        keys_to_delete.each_slice(::Uploads::Base::BATCH_SIZE) do |batch|
          ::DeleteStoredFilesWorker.perform_async(self.class, batch.pluck(:absolute_path))

          ::Geo::UploadReplicator.bulk_create_delete_events_async(batch)
        end
      end
    end
  end
end
