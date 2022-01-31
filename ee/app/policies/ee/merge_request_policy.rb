# frozen_string_literal: true

module EE
  module MergeRequestPolicy
    extend ActiveSupport::Concern

    prepended do
      with_scope :subject
      condition(:can_override_approvers, score: 0) do
        @subject.target_project&.can_override_approvers?
      end

      condition(:external_status_checks_enabled) do
        @subject.target_project&.licensed_feature_available?(:external_status_checks) &&
          can?(:developer_access, @subject.target_project)
      end

      condition(:over_storage_limit, scope: :subject) { @subject.target_project&.namespace&.over_storage_limit? }

      condition(:merge_request_group_approver, score: 140) do
        project = @subject.target_project
        protected_branch = project
          .protected_branches
          .find { |pb| pb.matches?(@subject.target_branch) }

        protected_branch.present? && group_access?(protected_branch)
      end

      def group_access?(protected_branch)
        protected_branch.approval_project_rules.for_groups(@user.group_members.reporters.select(:source_id)).exists?
      end

      rule { ~can_override_approvers }.prevent :update_approvers
      rule { can?(:update_merge_request) }.policy do
        enable :update_approvers
      end

      rule { merge_request_group_approver }.policy do
        enable :approve_merge_request
      end

      rule { external_status_checks_enabled }.enable :provide_status_check_response

      rule { over_storage_limit }.policy do
        prevent :approve_merge_request
        prevent :update_merge_request
        prevent :reopen_merge_request
        prevent :create_note
        prevent :resolve_note
      end
    end
  end
end
