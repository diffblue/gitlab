# frozen_string_literal: true

module EE
  module MergeRequestPresenter
    extend ::Gitlab::Utils::Override
    extend ::Gitlab::Utils::DelegatorOverride

    APPROVALS_WIDGET_FULL_TYPE = 'full'

    def api_approval_settings_path
      if expose_mr_approval_path?
        expose_path(api_v4_projects_merge_requests_approval_settings_path(id: project.id, merge_request_iid: merge_request.iid))
      end
    end

    def api_project_approval_settings_path
      if approval_feature_available?
        expose_path(api_v4_projects_approval_settings_path(id: project.id))
      end
    end

    def api_status_checks_path
      if expose_mr_status_checks?
        expose_path(api_v4_projects_merge_requests_status_checks_path(id: project.id, merge_request_iid: merge_request.iid))
      end
    end

    def merge_immediately_docs_path
      help_page_path('ci/pipelines/merge_trains.md', anchor: 'immediately-merge-a-merge-request-with-a-merge-train')
    end

    delegator_override :target_project
    def target_project
      merge_request.target_project.present(current_user: current_user)
    end

    def code_owner_rules_with_users
      @code_owner_rules ||= merge_request.approval_rules.code_owner.with_users.to_a
    end

    delegator_override :approver_groups
    def approver_groups
      ::ApproverGroup.filtered_approver_groups(merge_request.approver_groups, current_user)
    end

    def suggested_approvers
      merge_request.approval_state.suggested_approvers(current_user: current_user)
    end

    override :approvals_widget_type
    def approvals_widget_type
      expose_mr_approval_path? ? APPROVALS_WIDGET_FULL_TYPE : super
    end

    def discover_project_security_path
      project_security_discover_path(project) if show_discover_project_security?(project)
    end

    def issue_keys
      return [] unless project.jira_integration.try(:active?)

      Atlassian::JiraIssueKeyExtractor.new(
        merge_request.title,
        merge_request.description,
        custom_regex: project.jira_integration.reference_pattern
      ).issue_keys
    end

    private

    def expose_mr_status_checks?
      current_user.present? &&
        project.external_status_checks.applicable_to_branch(merge_request.target_branch).any?
    end

    def expose_mr_approval_path?
      approval_feature_available? && merge_request.iid
    end
  end
end

EE::MergeRequestPresenter.include_mod_with('ProjectsHelper')
