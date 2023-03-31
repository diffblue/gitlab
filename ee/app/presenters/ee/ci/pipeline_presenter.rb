# frozen_string_literal: true

module EE
  module Ci
    module PipelinePresenter
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::DelegatorOverride

      def expose_security_dashboard?
        return false unless can?(current_user, :read_security_resource, pipeline.project)

        batch_lookup_report_artifact_for_file_types(Ci::JobArtifact::SECURITY_REPORT_FILE_TYPES.map(&:to_sym)).present?
      end

      def degradation_threshold(file_type)
        if (job_artifact = batch_lookup_report_artifact_for_file_type(file_type)) &&
            can?(current_user, :read_build, job_artifact.job)
          job_artifact.job.degradation_threshold
        end
      end

      delegator_override :retryable?
      def retryable?
        # The merge_train_pipeline? is more expensive and less frequent condition
        super && !merge_train_pipeline?
      end
    end
  end
end
