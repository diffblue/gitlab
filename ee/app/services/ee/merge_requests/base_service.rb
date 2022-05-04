# frozen_string_literal: true

module EE
  module MergeRequests
    module BaseService
      extend ::Gitlab::Utils::Override

      private

      attr_accessor :blocking_merge_requests_params

      override :execute_external_hooks
      def execute_external_hooks(merge_request, merge_data)
        merge_request.project.execute_external_compliance_hooks(merge_data)
      end

      override :filter_params
      def filter_params(merge_request)
        unless current_user.can?(:update_approvers, merge_request)
          params.delete(:approvals_before_merge)
          params.delete(:approver_ids)
          params.delete(:approver_group_ids)
        end

        self.params = ApprovalRules::ParamsFilteringService.new(merge_request, current_user, params).execute

        self.blocking_merge_requests_params =
          ::MergeRequests::UpdateBlocksService.extract_params!(params)

        super
      end

      def reset_approvals?(merge_request, _newrev)
        merge_request.target_project.reset_approvals_on_push
      end

      def reset_approvals(merge_request, newrev = nil)
        return unless reset_approvals?(merge_request, newrev)

        merge_request.approvals.delete_all
        create_new_approval_todos_for_all_approvers(merge_request)
      end

      def all_approvers(merge_request)
        merge_request.overall_approvers(exclude_code_owners: true)
      end

      def create_new_approval_todos_for_all_approvers(merge_request)
        return unless ::Feature.enabled?(:create_approval_todos_on_mr_update, merge_request.project)
        return if merge_request.closed?

        todo_service.add_merge_request_approvers(merge_request, all_approvers(merge_request))
      end
    end
  end
end
