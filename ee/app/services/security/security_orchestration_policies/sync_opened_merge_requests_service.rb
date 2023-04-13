# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class SyncOpenedMergeRequestsService < BaseMergeRequestsService
      def initialize(project:, policy_configuration:)
        super(project: project)

        @policy_configuration = policy_configuration
      end

      def execute
        each_open_merge_request do |merge_request|
          merge_request.sync_project_approval_rules_for_policy_configuration(@policy_configuration.id)

          unless merge_request.head_pipeline_id.nil?
            ::Ci::SyncReportsToReportApprovalRulesWorker.perform_async(merge_request.head_pipeline_id)
          end
        end
      end
    end
  end
end
