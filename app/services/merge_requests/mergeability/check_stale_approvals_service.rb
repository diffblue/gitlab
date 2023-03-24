# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckStaleApprovalsService < CheckBaseService
      include Gitlab::Utils::StrongMemoize

      def execute
        # When approvals might be reset, they _could_ potentially still exist but
        #   be outdated, waiting for an async process to remove them. If so, we
        #   should run this check. If resetting approvals is NOT enabled, then
        #   return a success and move on.
        #
        return success unless reset_approvals_on_push?

        if all_approvals_current?
          success
        else
          failure(reason: failure_reason)
        end
      end

      def skip?
        false
      end

      def cacheable?
        false
      end

      private

      def all_approvals_current?
        Approval.approved_shas_for(eligible_approvals).all?(/#{merge_request.diff_head_sha}/)
      end

      def eligible_approvals
        merge_request.approvals
      end
      strong_memoize_attr :eligible_approvals

      def reset_approvals_on_push?
        merge_request.target_project.reset_approvals_on_push
      end

      def failure_reason
        :stale_approvals
      end
    end
  end
end
