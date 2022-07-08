# frozen_string_literal: true

module EE
  module Ci
    module JobArtifacts
      module CreateService
        extend ::Gitlab::Utils::Override

        METRICS_REPORT_UPLOAD_EVENT_NAME = 'i_testing_metrics_report_artifact_uploaders'

        override :track_artifact_uploader
        def track_artifact_uploader(artifact)
          super
          return unless artifact.file_type == 'metrics'

          track_usage_event(METRICS_REPORT_UPLOAD_EVENT_NAME, job.user_id)
        end
      end
    end
  end
end
