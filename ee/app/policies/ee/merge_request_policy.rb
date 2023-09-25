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

      with_scope :subject
      condition(:summarize_draft_code_review_enabled) do
        namespace = @subject&.project&.group&.root_ancestor

        next if namespace.nil?

        ::Feature.enabled?(:summarize_my_code_review, @user) &&
          namespace.group_namespace? &&
          namespace.licensed_feature_available?(:summarize_my_mr_code_review) &&
          ::Gitlab::Llm::StageCheck.available?(namespace, :summarize_my_mr_code_review)
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

      with_scope :subject
      condition(:ai_features_enabled) do
        ::Feature.enabled?(:openai_experimentation)
      end

      with_scope :subject
      condition(:summarize_submitted_review_enabled) do
        ::Feature.enabled?(:automatically_summarize_mr_review, subject.project) &&
          subject.project.licensed_feature_available?(:summarize_submitted_review) &&
          ::Gitlab::Llm::StageCheck.available?(subject.project.root_ancestor, :summarize_submitted_review)
      end

      condition(:role_enables_admin_merge_request) do
        next unless @user.is_a?(User)

        @user.custom_permission_for?(subject&.project, :admin_merge_request)
      end

      with_scope :subject
      condition(:custom_roles_allowed) do
        subject&.project&.custom_roles_enabled?
      end

      with_scope :subject
      condition(:summarize_merge_request_enabled) do
        ::Feature.enabled?(:summarize_diff_automatically, subject.project) &&
          subject.project.licensed_feature_available?(:summarize_mr_changes) &&
          ::Gitlab::Llm::StageCheck.available?(subject.project.root_ancestor, :summarize_diff)
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

      rule { summarize_draft_code_review_enabled }.enable :summarize_draft_code_review

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

      rule do
        ai_features_enabled & summarize_submitted_review_enabled & can?(:read_merge_request)
      end.enable :summarize_submitted_review

      rule { custom_roles_allowed & role_enables_admin_merge_request }.policy do
        enable :approve_merge_request
      end

      rule do
        ai_features_enabled & summarize_merge_request_enabled & can?(:generate_diff_summary)
      end.enable :summarize_merge_request
    end

    private

    override :can_approve?
    def can_approve?
      return can?(:developer_access) if read_only?

      super
    end
  end
end
