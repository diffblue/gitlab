# frozen_string_literal: true

module Gitlab
  module Geo
    module LogCursor
      module Events
        class JobArtifactDeletedEvent
          include BaseEvent

          def process
            # Must always schedule, regardless of shard health
            job_id = ::Geo::FileRegistryRemovalWorker.perform_async(:job_artifact, event.job_artifact_id, file_path)
            log_event(job_id)
          end

          private

          def file_path
            @file_path ||= File.join(::JobArtifactUploader.root, event.file_path)
          end

          def log_event(job_id)
            super(
              'Delete job artifact scheduled',
              file_id: event.job_artifact_id,
              file_path: event.file_path,
              job_id: job_id,
              uploader_class: 'JobArtifactUploader')
          end
        end
      end
    end
  end
end
