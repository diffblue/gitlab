# frozen_string_literal: true

module ComplianceManagement
  module MergeRequests
    class ComplianceViolationsWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3
      idempotent!

      feature_category :compliance_management

      def perform(merge_request_id)
        merge_request = MergeRequest.find_by_id(merge_request_id)

        return unless merge_request

        ComplianceManagement::MergeRequests::CreateComplianceViolationsService.new(merge_request).execute
      end
    end
  end
end
