# frozen_string_literal: true

module EE
  module ProtectedBranches
    module CreateService
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize
      include Loggable

      override :execute
      def execute(skip_authorization: false)
        super(skip_authorization: skip_authorization).tap do |protected_branch_service|
          log_audit_event(protected_branch_service, :add)
        end
      end

      private

      override :save_protected_branch
      def save_protected_branch
        protected_branch.code_owner_approval_required = false unless project_or_group.feature_available?(:code_owner_approval_required)

        super

        sync_scan_finding_approval_rules
        sync_code_owner_approval_rules
        track_onboarding_progress

        protected_branch
      end

      def sync_code_owner_approval_rules
        return if project_or_group.is_a?(Group) # Group-level MVC does not support this currently
        return unless project_or_group.feature_available?(:code_owners)

        merge_requests_for_protected_branch.each do |merge_request|
          ::MergeRequests::SyncCodeOwnerApprovalRules.new(merge_request).execute
        end
      end

      def merge_requests_for_protected_branch
        strong_memoize(:protected_branch_merge_requests) do
          if protected_branch.wildcard?
            merge_requests_for_wildcard_branch
          else
            merge_requests_for_branch
          end
        end
      end

      def merge_requests_for_wildcard_branch
        project_or_group.merge_requests
          .open_and_closed
          .by_target_branch_wildcard(protected_branch.name)
          .preload_source_project
          .select(&:source_project)
      end

      def merge_requests_for_branch
        project_or_group.merge_requests
          .open_and_closed
          .by_target_branch(protected_branch.name)
          .preload_source_project
          .select(&:source_project)
      end

      def track_onboarding_progress
        return if project_or_group.is_a?(Group) # Group-level MVC does not support this currently
        return unless protected_branch.code_owner_approval_required

        Onboarding::ProgressService.new(project_or_group.namespace).execute(action: :code_owners_enabled)
      end
    end
  end
end
