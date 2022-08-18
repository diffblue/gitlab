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
    end
  end
end
