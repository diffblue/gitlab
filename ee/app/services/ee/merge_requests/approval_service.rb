# frozen_string_literal: true

module EE
  module MergeRequests
    module ApprovalService
      extend ::Gitlab::Utils::Override

      IncorrectApprovalPasswordError = Class.new(StandardError)

      override :execute
      def execute(merge_request)
        return if incorrect_approval_password?(merge_request)

        super
      end

      private

      def incorrect_approval_password?(merge_request)
        merge_request.project.require_password_to_approve? &&
          !::Gitlab::Auth.find_with_user_password(current_user.username, params[:approval_password])
      end

      override :can_be_approved?
      def can_be_approved?(merge_request)
        merge_request.can_approve?(current_user)
      end

      override :reset_approvals_cache
      def reset_approvals_cache(merge_request)
        merge_request.reset_approval_cache!
      end

      override :create_event
      def create_event(merge_request)
        # Making sure MergeRequest::Metrics updates are in sync with
        # Event creation.
        ::Event.transaction do
          super
          calculate_approvals_metrics(merge_request)
        end
      end

      override :stream_audit_event
      def stream_audit_event(merge_request)
        audit_context = {
          name: 'merge_request_approval_operation',
          stream_only: true,
          author: current_user,
          scope: merge_request.project,
          target: merge_request,
          message: 'Approved merge request'
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end

      override :execute_approval_hooks
      def execute_approval_hooks(merge_request, current_user)
        if merge_request.approvals_left == 0
          super
        else
          execute_hooks(merge_request, 'approval')
        end
      end

      def calculate_approvals_metrics(merge_request)
        return unless merge_request.project.licensed_feature_available?(:code_review_analytics)

        ::Analytics::RefreshApprovalsData.new(merge_request).execute
      end
    end
  end
end
