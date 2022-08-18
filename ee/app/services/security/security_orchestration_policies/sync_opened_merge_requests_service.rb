# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class SyncOpenedMergeRequestsService < BaseMergeRequestsService
      def execute
        each_open_merge_request do |merge_request|
          MergeRequests::SyncReportApproverApprovalRules
            .new(merge_request)
            .execute(skip_authentication: true)
        end
      end
    end
  end
end
