# frozen_string_literal: true

module EE
  module MergeRequestPolicy
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      with_scope :subject
      condition(:can_override_approvers, score: 0) do
        @subject.target_project&.can_override_approvers?
      end

      condition(:external_status_checks_enabled) do
        @subject.target_project&.licensed_feature_available?(:external_status_checks) &&
          can?(:developer_access, @subject.target_project)
      end

      condition(:read_only, scope: :subject) { read_only? }
      condition(:merge_request_discussion_locked) { @subject.discussion_locked? }
      condition(:merge_request_project_archived) { @subject.project.archived? }

      condition(:merge_request_group_approver, score: 140) do
        project = @subject.target_project
        protected_branch = project
          .protected_branches
          .find { |pb| pb.matches?(@subject.target_branch) }

        protected_branch.present? && group_access?(protected_branch)
      end

      condition(:approval_rules_licence_enabled, scope: :subject) do
        @subject.target_project.licensed_feature_available?(:coverage_check_approval_rule) ||
        @subject.target_project.licensed_feature_available?(:report_approver_rules)
      end

      def read_only?
        @subject.target_project&.namespace&.read_only?
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

      rule { external_status_checks_enabled }.policy do
        enable :provide_status_check_response
        enable :retry_failed_status_checks
      end

      rule { read_only }.policy do
        prevent :update_merge_request
      end

      rule { merge_request_discussion_locked | merge_request_project_archived }.policy do
        prevent :create_visual_review_note
      end

      rule { ~merge_request_discussion_locked & ~merge_request_project_archived }.policy do
        enable :create_visual_review_note
      end

      rule { approval_rules_licence_enabled }.enable :create_merge_request_approval_rules
    end

    private

    override :can_approve?
    def can_approve?
      return can?(:developer_access) if read_only?

      super
    end
  end
end
