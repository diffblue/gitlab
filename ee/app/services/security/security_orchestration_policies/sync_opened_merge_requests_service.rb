# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class SyncOpenedMergeRequestsService
      def initialize(policy_configuration:)
        @project = policy_configuration.project
      end

      def execute
        opened_merge_requests.each do |merge_request|
          merge_request.approval_rules.scan_finding.delete_all

          # Does not reuse the existing SyncReportApproverApprovalRules as there
          # is no current_user available in the caller.
          merge_request.synchronize_approval_rules_from_target_project
        end
      end

      private

      def opened_merge_requests
        @project.merge_requests.opened
      end
    end
  end
end
