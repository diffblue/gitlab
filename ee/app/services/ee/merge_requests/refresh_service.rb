# frozen_string_literal: true

module EE
  module MergeRequests
    module RefreshService
      extend ::Gitlab::Utils::Override

      private

      override :refresh_merge_requests!
      def refresh_merge_requests!
        check_merge_train_status

        super

        update_approvers_for_source_branch_merge_requests
        update_approvers_for_target_branch_merge_requests
        reset_approvals_for_merge_requests(push.ref, push.newrev)
        trigger_suggested_reviewers_fetch
      end

      def trigger_suggested_reviewers_fetch
        return unless project.can_suggest_reviewers?

        merge_requests_for_source_branch.each do |mr|
          next unless mr.can_suggest_reviewers?

          ::MergeRequests::FetchSuggestedReviewersWorker.perform_async(mr.id)
        end
      end

      def reset_approvals_for_merge_requests(ref, newrev)
        # We need to make sure the code owner approval rules have all been synced first, so we delay for 10s
        # We are trying to pin down and fix the race condition: https://gitlab.com/gitlab-org/gitlab/-/issues/373846
        MergeRequestResetApprovalsWorker.perform_in(10.seconds, project.id, current_user.id, ref, newrev)
      end

      def update_approvers_for_source_branch_merge_requests
        merge_requests_for_source_branch.each do |merge_request|
          ::MergeRequests::SyncCodeOwnerApprovalRules.new(merge_request).execute if project.feature_available?(:code_owners)
          ::MergeRequests::SyncReportApproverApprovalRules.new(merge_request, current_user).execute
        end
      end

      def update_approvers_for_target_branch_merge_requests
        if project.feature_available?(:code_owners) && branch_protected? && code_owners_updated?
          merge_requests_for_target_branch.each do |merge_request|
            ::MergeRequests::SyncCodeOwnerApprovalRules.new(merge_request).execute unless merge_request.on_train?
          end
        end
      end

      def branch_protected?
        project.branch_requires_code_owner_approval?(push.branch_name)
      end

      def code_owners_updated?
        return unless push.branch_updated?

        push.modified_paths.find { |path| ::Gitlab::CodeOwners::FILE_PATHS.include?(path) }
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      def check_merge_train_status
        return unless @push.branch_updated?

        MergeTrains::CheckStatusService.new(project, current_user)
          .execute(project, @push.branch_name, @push.newrev)
      end

      def merge_requests_for_target_branch(reload: false, mr_states: [:opened])
        @target_merge_requests = nil if reload
        @target_merge_requests ||= project.merge_requests
          .with_state(mr_states)
          .by_target_branch(push.branch_name)
          .including_merge_train
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables
    end
  end
end
