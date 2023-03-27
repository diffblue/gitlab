# frozen_string_literal: true

module EE::SecurityOrchestrationHelper
  LICENSE_CHECK_DEPRECATION_ALERT = 'license_check_deprecation_alert'

  def show_license_check_alert?(project)
    return false if current_path?('projects/settings/merge_requests#show')
    return false if current_path?('projects/settings/merge_requests#update')

    show_license_check_settings_alert?(project)
  end

  def show_license_check_settings_alert?(project)
    return false unless Feature.enabled?(:license_scanning_policies, project)
    return false if user_dismissed?(LICENSE_CHECK_DEPRECATION_ALERT, object: project)

    project
      .approval_rules
      .report_approver
      .exists?(name: ApprovalRuleLike::DEFAULT_NAME_FOR_LICENSE_REPORT) # rubocop:disable CodeReuse/ActiveRecord
  end

  def deprecate_license_alert_message(project)
    link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe

    format(
      _(
        '%{license_check_docs_link_start}License-Check%{link_end} is enabled for this project. ' \
        'This feature has been %{deprecation_docs_link_url}deprecated%{link_end} in GitLab 15.9 ' \
        'and is planned for %{removal_docs_link_url}removal%{link_end} in 16.0. ' \
        'You can create a %{scan_result_policy_link_start}scan result policy%{link_end} to ' \
        'continue enforcing your license approval requirements.'
      ),
      license_check_docs_link_start: format(link_start, url: project_settings_merge_requests_path(project)),
      deprecation_docs_link_url: format(link_start, url: help_page_path('update/deprecations')),
      removal_docs_link_url: format(link_start, url: help_page_path('update/removals')),
      scan_result_policy_link_start: format(link_start, url: scan_result_policy_path(project)),
      link_end: '</a>'.html_safe
    ).html_safe
  end

  def deprecate_license_alert_settings_message(project)
    link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe

    format(
      _(
        'License-Check has been %{deprecation_docs_link_url}deprecated%{link_end} in GitLab 15.9 ' \
        'and is planned for %{removal_docs_link_url}removal%{link_end} in 16.0. You can create a ' \
        '%{scan_result_policy_link_start}scan result policy%{link_end} to continue enforcing your ' \
        'license approval requirements.'
      ),
      deprecation_docs_link_url: format(link_start, url: help_page_path('update/deprecations')),
      removal_docs_link_url: format(link_start, url: help_page_path('update/removals')),
      scan_result_policy_link_start: format(link_start, url: scan_result_policy_path(project)),
      link_end: '</a>'.html_safe
    ).html_safe
  end

  def scan_result_policy_path(project)
    path = project_security_policies_path(project)

    return path unless can_modify_security_policy?(project)

    new_project_security_policy_path(project, type: 'scan_result_policy')
  end

  def can_update_security_orchestration_policy_project?(container)
    can?(current_user, :update_security_orchestration_policy_project, container)
  end

  def can_modify_security_policy?(container)
    can?(current_user, :modify_security_policy, container)
  end

  def assigned_policy_project(container)
    return unless container&.security_orchestration_policy_configuration

    orchestration_policy_configuration = container.security_orchestration_policy_configuration
    security_policy_management_project = orchestration_policy_configuration.security_policy_management_project

    {
      id: security_policy_management_project.to_global_id.to_s,
      name: security_policy_management_project.name,
      full_path: security_policy_management_project.full_path,
      branch: security_policy_management_project.default_branch_or_main
    }
  end

  def orchestration_policy_data(container, policy_type = nil, policy = nil, approvers = nil)
    return unless container

    disable_scan_policy_update = !can_modify_security_policy?(container)

    policy_data = {
      assigned_policy_project: assigned_policy_project(container).to_json,
      disable_scan_policy_update: disable_scan_policy_update.to_s,
      namespace_id: container.id,
      namespace_path: container.full_path,
      policies_path: security_policies_path(container),
      policy: policy&.to_json,
      policy_editor_empty_state_svg_path: image_path('illustrations/monitoring/unable_to_connect.svg'),
      policy_type: policy_type,
      role_approver_types: Gitlab::Access.sym_options_with_owner.keys.map(&:to_s),
      scan_policy_documentation_path: help_page_path('user/application_security/policies/index'),
      scan_result_approvers: approvers&.to_json,
      software_licenses: SoftwareLicense.all_license_names,
      global_group_approvers_enabled: Gitlab::CurrentSettings.security_policy_global_group_approvers_enabled.to_json,
      root_namespace_path: container.root_ancestor&.full_path
    }

    if container.is_a?(::Project)
      policy_data.merge(
        create_agent_help_path: help_page_url('user/clusters/agent/install/index')
      )
    else
      policy_data
    end
  end

  def security_policies_path(container)
    container.is_a?(::Project) ? project_security_policies_path(container) : group_security_policies_path(container)
  end
end
