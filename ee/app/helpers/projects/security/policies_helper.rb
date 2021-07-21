# frozen_string_literal: true

module Projects::Security::PoliciesHelper
  def assigned_policy_project(project)
    return unless project&.security_orchestration_policy_configuration

    orchestration_policy_configuration = project.security_orchestration_policy_configuration
    security_policy_management_project = orchestration_policy_configuration.security_policy_management_project

    { id: security_policy_management_project.to_global_id.to_s, name: security_policy_management_project.name }
  end
end
