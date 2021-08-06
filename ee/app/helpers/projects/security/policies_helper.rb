# frozen_string_literal: true

module Projects::Security::PoliciesHelper
  def assigned_policy_project(project)
    return unless project&.security_orchestration_policy_configuration

    orchestration_policy_configuration = project.security_orchestration_policy_configuration
    security_policy_management_project = orchestration_policy_configuration.security_policy_management_project

    {
      id: security_policy_management_project.to_global_id.to_s,
      name: security_policy_management_project.name,
      full_path: security_policy_management_project.full_path,
      branch: security_policy_management_project.default_branch_or_main
    }
  end

  def orchestration_policy_data(project, policy_type, policy, environment = nil)
    return unless project && policy

    {
      network_policies_endpoint: project_security_network_policies_path(project),
      configure_agent_help_path: help_page_url('user/clusters/agent/repository.html'),
      create_agent_help_path: help_page_url('user/clusters/agent/index.md', anchor: 'create-an-agent-record-in-gitlab'),
      environments_endpoint: project_environments_path(project),
      environment_id: environment&.id,
      project_path: project.full_path,
      project_id: project.id,
      policy: policy.to_json,
      policy_type: policy_type,
      threat_monitoring_path: project_threat_monitoring_path(project)
    }
  end
end
