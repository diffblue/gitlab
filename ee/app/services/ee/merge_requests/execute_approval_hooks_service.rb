# frozen_string_literal: true

module EE
  module MergeRequests
    module ExecuteApprovalHooksService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(merge_request)
        if merge_request.approvals_left == 0
          super
        else
          execute_hooks(merge_request, 'approval')
        end
      end
    end
  end
end
