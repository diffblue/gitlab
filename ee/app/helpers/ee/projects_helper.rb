# frozen_string_literal: true

module EE
  module ProjectsHelper
    extend ::Gitlab::Utils::Override

    override :sidebar_operations_paths
    def sidebar_operations_paths
      super + %w[
        cluster_agents
        oncall_schedules
      ]
    end

    override :project_permissions_settings
    def project_permissions_settings(project)
      settings = super.merge(
        requirementsAccessLevel: project.requirements_access_level
      )

      if ::Feature.enabled?(:cve_id_request_button, project)
        settings[:cveIdRequestEnabled] = project.public? && project.project_setting.cve_id_request_enabled?
      end

      settings
    end

    override :project_permissions_panel_data
    def project_permissions_panel_data(project)
      panel_data = super.merge(
        requirementsAvailable: project.feature_available?(:requirements)
      )

      if ::Feature.enabled?(:cve_id_request_button, project)
        panel_data[:requestCveAvailable] = ::Gitlab.com?
        panel_data[:cveIdRequestHelpPath] = help_page_path('user/application_security/cve_id_request')
      end

      panel_data
    end

    override :default_url_to_repo
    def default_url_to_repo(project = @project)
      case default_clone_protocol
      when 'krb5'
        project.kerberos_url_to_repo
      else
        super
      end
    end

    override :extra_default_clone_protocol
    def extra_default_clone_protocol
      if alternative_kerberos_url? && current_user
        "krb5"
      else
        super
      end
    end

    override :remove_project_message
    def remove_project_message(project)
      return super unless project.adjourned_deletion?

      date = permanent_deletion_date(Time.now.utc)
      _("Deleting a project places it into a read-only state until %{date}, at which point the project will be permanently deleted. Are you ABSOLUTELY sure?") %
        { date: date }
    end

    def approvals_app_data(project = @project)
      {
        data: {
          'project_id': project.id,
          'can_edit': can_modify_approvers.to_s,
          'project_path': expose_path(api_v4_projects_path(id: project.id)),
          'settings_path': expose_path(api_v4_projects_approval_settings_path(id: project.id)),
          'rules_path': expose_path(api_v4_projects_approval_settings_rules_path(id: project.id)),
          'allow_multi_rule': project.multiple_approval_rules_available?.to_s,
          'eligible_approvers_docs_path': help_page_path('user/project/merge_requests/approvals/rules', anchor: 'eligible-approvers'),
          'security_approvals_help_page_path': help_page_path('user/application_security/index', anchor: 'security-approvals-in-merge-requests'),
          'security_configuration_path': project_security_configuration_path(project),
          'vulnerability_check_help_page_path': help_page_path('user/application_security/index', anchor: 'security-approvals-in-merge-requests'),
          'license_check_help_page_path': help_page_path('user/application_security/index', anchor: 'enabling-license-approvals-within-a-project'),
          'coverage_check_help_page_path': help_page_path('ci/pipelines/settings', anchor: 'coverage-check-approval-rule')
        }
      }
    end

    def status_checks_app_data(project)
      {
        data: {
          project_id: project.id,
          status_checks_path: expose_path(api_v4_projects_external_status_checks_path(id: project.id))
        }
      }
    end

    def can_modify_approvers(project = @project)
      can?(current_user, :modify_approvers_rules, project)
    end

    def permanent_delete_message(project)
      message = _('This action will %{strongOpen}permanently delete%{strongClose} %{codeOpen}%{project}%{codeClose} %{strongOpen}immediately%{strongClose}, including its repositories and all related resources, including issues and merge requests.')
      html_escape(message) % remove_message_data(project)
    end

    def marked_for_removal_message(project)
      date = permanent_deletion_date(Time.now.utc)
      message = _('This action will %{strongOpen}permanently delete%{strongClose} %{codeOpen}%{project}%{codeClose} %{strongOpen}on %{date}%{strongClose}, including its repositories and all related resources, including issues and merge requests.')
      html_escape(message) % remove_message_data(project).merge(date: date)
    end

    def permanent_deletion_date(date)
      (date + ::Gitlab::CurrentSettings.deletion_adjourned_period.days).strftime('%F')
    end

    # Given the current GitLab configuration, check whether the GitLab URL for Kerberos is going to be different than the HTTP URL
    def alternative_kerberos_url?
      ::Gitlab.config.alternative_gitlab_kerberos_url?
    end

    def can_change_push_rule?(push_rule, rule, context)
      return true if push_rule.global?

      can?(current_user, :"change_#{rule}", context)
    end

    def ci_cd_projects_available?
      ::License.feature_available?(:ci_cd_projects) && import_sources_enabled?
    end

    def merge_pipelines_available?
      return false unless @project.builds_enabled?

      @project.feature_available?(:merge_pipelines)
    end

    def merge_trains_available?
      return false unless @project.builds_enabled?

      @project.feature_available?(:merge_trains)
    end

    def size_limit_message(project)
      show_lfs = project.lfs_enabled? ? 'including LFS files' : ''

      "Max size of this project's repository, #{show_lfs}. For no limit, enter 0. To inherit the group/global value, leave blank."
    end

    override :membership_locked?
    def membership_locked?
      group = @project.group

      return false unless group

      group.membership_lock? || ::Gitlab::CurrentSettings.lock_memberships_to_ldap?
    end

    def group_project_templates_count(group_id)
      allowed_subgroups = current_user.available_subgroups_with_custom_project_templates(group_id)

      ::Project.in_namespace(allowed_subgroups).not_aimed_for_deletion.count
    end

    def project_security_dashboard_config(project)
      if project.vulnerabilities.none?
        {
          has_vulnerabilities: 'false',
          has_jira_vulnerabilities_integration_enabled: project.configured_to_create_issues_from_vulnerabilities?.to_s,
          empty_state_svg_path: image_path('illustrations/security-dashboard_empty.svg'),
          survey_request_svg_path: image_path('illustrations/security-dashboard_empty.svg'),
          security_dashboard_help_path: help_page_path('user/application_security/security_dashboard/index'),
          no_vulnerabilities_svg_path: image_path('illustrations/issues.svg'),
          project_full_path: project.full_path,
          security_configuration_path: project_security_configuration_path(@project)
        }.merge!(security_dashboard_pipeline_data(project))
      else
        {
          has_vulnerabilities: 'true',
          has_jira_vulnerabilities_integration_enabled: project.configured_to_create_issues_from_vulnerabilities?.to_s,
          project: { id: project.id, name: project.name },
          project_full_path: project.full_path,
          vulnerabilities_export_endpoint: api_v4_security_projects_vulnerability_exports_path(id: project.id),
          empty_state_svg_path: image_path('illustrations/security-dashboard-empty-state.svg'),
          survey_request_svg_path: image_path('illustrations/security-dashboard_empty.svg'),
          no_vulnerabilities_svg_path: image_path('illustrations/issues.svg'),
          dashboard_documentation: help_page_path('user/application_security/security_dashboard/index'),
          not_enabled_scanners_help_path: help_page_path('user/application_security/index', anchor: 'quick-start'),
          no_pipeline_run_scanners_help_path: new_project_pipeline_path(project),
          security_dashboard_help_path: help_page_path('user/application_security/security_dashboard/index'),
          auto_fix_documentation: help_page_path('user/application_security/index', anchor: 'auto-fix-merge-requests'),
          auto_fix_mrs_path: project_merge_requests_path(@project, label_name: 'GitLab-auto-fix'),
          scanners: VulnerabilityScanners::ListService.new(project).execute.to_json,
          can_admin_vulnerability: can?(current_user, :admin_vulnerability, project).to_s
        }.merge!(security_dashboard_pipeline_data(project))
      end
    end

    def can_update_security_orchestration_policy_project?(project)
      can?(current_user, :update_security_orchestration_policy_project, project)
    end

    def can_create_feedback?(project, feedback_type)
      feedback = Vulnerabilities::Feedback.new(project: project, feedback_type: feedback_type)
      can?(current_user, :create_vulnerability_feedback, feedback)
    end

    def create_vulnerability_feedback_issue_path(project)
      if can_create_feedback?(project, :issue)
        project_vulnerability_feedback_index_path(project)
      end
    end

    def create_vulnerability_feedback_merge_request_path(project)
      if can_create_feedback?(project, :merge_request)
        project_vulnerability_feedback_index_path(project)
      end
    end

    def create_vulnerability_feedback_dismissal_path(project)
      if can_create_feedback?(project, :dismissal)
        project_vulnerability_feedback_index_path(project)
      end
    end

    def show_discover_project_security?(project)
      !!current_user &&
        ::Gitlab.com? &&
        !project.feature_available?(:security_dashboard) &&
        can?(current_user, :admin_namespace, project.root_ancestor)
    end

    override :can_import_members?
    def can_import_members?
      super && !membership_locked?
    end

    def show_compliance_framework_badge?(project)
      project&.compliance_framework_setting&.compliance_management_framework.present?
    end

    def scheduled_for_deletion?(project)
      project.marked_for_deletion_at.present?
    end

    private

    def remove_message_data(project)
      {
        project: project.path,
        strongOpen: '<strong>'.html_safe,
        strongClose: '</strong>'.html_safe,
        codeOpen: '<code>'.html_safe,
        codeClose: '</code>'.html_safe
      }
    end

    def security_dashboard_pipeline_data(project)
      pipeline = project.latest_pipeline_with_security_reports
      return {} unless pipeline

      {
        pipeline: {
          id: pipeline.id,
          path: pipeline_path(pipeline),
          created_at: pipeline.created_at.to_s(:iso8601),
          security_builds: {
            failed: {
              count: pipeline.latest_failed_security_builds.count,
              path: failures_project_pipeline_path(pipeline.project, pipeline)
            }
          }
        }
      }
    end
  end
end
