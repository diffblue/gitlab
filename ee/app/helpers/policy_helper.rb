# frozen_string_literal: true

module PolicyHelper
  def policy_details(project, policy = nil, environment = nil)
    return unless project

    details = details(project)
    return details unless policy && environment

    edit_details = {
      policy: policy.to_json,
      environment_id: environment.id
    }
    details.merge(edit_details)
  end

  def threat_monitoring_alert_details_data(project, alert_iid)
    {
      'alert-id' => alert_iid,
      'project-path' => project.full_path,
      'project-id' => project.id,
      'project-issues-path' => project_issues_path(project),
      'page' => 'THREAT_MONITORING'
    }
  end

  private

  def details(project)
    disable_scan_execution_update = !can_update_security_orchestration_policy_project?(project)

    {
      assigned_policy_project: assigned_policy_project(project).to_json,
      disable_scan_execution_update: disable_scan_execution_update.to_s,
      network_policies_endpoint: project_security_network_policies_path(project),
      configure_agent_help_path: help_page_url('user/clusters/agent/repository.html'),
      create_agent_help_path: help_page_url('user/clusters/agent/index.md', anchor: 'create-an-agent-record-in-gitlab'),
      environments_endpoint: project_environments_path(project),
      project_path: project.full_path,
      project_id: project.id,
      threat_monitoring_path: project_threat_monitoring_path(project)
    }
  end
end
