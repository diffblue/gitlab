# frozen_string_literal: true

module EE
  module MergeRequests
    module CreateApprovalEventService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(merge_request)
        # Making sure MergeRequest::Metrics updates are in sync with
        # Event creation.
        ::Event.transaction do
          super
          calculate_approvals_metrics(merge_request)
        end
      end

      private

      def calculate_approvals_metrics(merge_request)
        return unless merge_request.project.licensed_feature_available?(:code_review_analytics)

        ::Analytics::RefreshApprovalsData.new(merge_request).execute
      end
    end
  end
end
