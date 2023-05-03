# frozen_string_literal: true

module EE
  module MergeRequests
    module UpdateService
      extend ::Gitlab::Utils::Override

      private

      override :general_fallback
      def general_fallback(merge_request)
        unless update_task_event?
          old_approvers = merge_request.overall_approvers(exclude_code_owners: true)
        end

        reset_approval_rules(merge_request) if params.delete(:reset_approval_rules_to_defaults)

        merge_request = super(merge_request)

        merge_request.reset_approval_cache!

        return merge_request if update_task_event?

        new_approvers = all_approvers(merge_request) - old_approvers

        if ::Feature.disabled?(:no_todo_for_approvers, merge_request.target_project) && new_approvers.any?
          todo_service.add_merge_request_approvers(merge_request, new_approvers)
          notification_service.add_merge_request_approvers(merge_request, new_approvers, current_user)
        end

        ::MergeRequests::UpdateBlocksService
          .new(merge_request, current_user, blocking_merge_requests_params)
          .execute

        merge_request
      end

      override :after_update
      def after_update(merge_request, old_associations)
        super

        merge_request.run_after_commit do
          ::MergeRequests::SyncCodeOwnerApprovalRulesWorker.perform_async(merge_request.id)
        end
      end

      override :create_branch_change_note
      def create_branch_change_note(merge_request, branch_type, event_type, old_branch, new_branch)
        super

        reset_approvals(merge_request)
      end

      def reset_approval_rules(merge_request)
        return unless merge_request.project.can_override_approvers?

        merge_request.approval_rules.regular_or_any_approver.delete_all
      end
    end
  end
end
