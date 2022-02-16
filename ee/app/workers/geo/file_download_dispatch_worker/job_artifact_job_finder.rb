# frozen_string_literal: true

module Geo
  class FileDownloadDispatchWorker # rubocop:disable Scalability/IdempotentWorker
    class JobArtifactJobFinder < JobFinder # rubocop:disable Scalability/IdempotentWorker
      RESOURCE_ID_KEY = :artifact_id
      EXCEPT_RESOURCE_IDS_KEY = :except_ids
      FILE_SERVICE_OBJECT_TYPE = :job_artifact

      def registry_finder
        @registry_finder ||= Geo::JobArtifactLegacyRegistryFinder.new
      end
    end
  end
end
