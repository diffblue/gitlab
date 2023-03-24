# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckStaleCodeOwnerApprovalsService < CheckBaseService
      include Gitlab::Utils::StrongMemoize

      def execute
        # When approvals might be reset, they _could_ potentially still exist but
        #   be outdated, waiting for an async process to remove them. If so, we
        #   should run this check. If resetting approvals is NOT enabled, then
        #   return a success and move on.
        #
        return success unless selective_code_owner_removals?

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
        # We only want to consider approvals that relate directly to a code
        #   owners approval rule
        #
        return [] unless approved_code_owner_rules.any?

        rule_names = ::Gitlab::CodeOwners.entries_since_merge_request_commit(merge_request).map(&:pattern)
        match_ids = approved_code_owner_rules.flat_map do |rule|
          next unless rule_names.include?(rule.name)

          rule.approved_approvers.map(&:id)
        end.compact

        merge_request.approvals.where(user_id: match_ids) # rubocop: disable CodeReuse/ActiveRecord
      end
      strong_memoize_attr :eligible_approvals

      def approved_code_owner_rules
        merge_request.wrapped_approval_rules.select { |rule| rule.code_owner? && rule.approved_approvers.any? }
      end
      strong_memoize_attr :approved_code_owner_rules

      def selective_code_owner_removals?
        merge_request.target_project.project_setting.selective_code_owner_removals
      end

      def failure_reason
        :stale_code_owner_approvals
      end
    end
  end
end
