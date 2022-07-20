# frozen_string_literal: true

module EE::Projects::DisableDeployKeyService
  extend ActiveSupport::Concern
  extend ::Gitlab::Utils::Override

  override :execute
  def execute
    super.tap do |deploy_key_project|
      break unless deploy_key_project

      log_audit_event(deploy_key_project.deploy_key)
    end
  end

  private

  def log_audit_event(key)
    audit_context = {
      name: 'deploy_key_removed',
      author: current_user,
      scope: project,
      target: key,
      message: "Removed deploy key",
      additional_details: { remove: "deploy_key" }
    }

    ::Gitlab::Audit::Auditor.audit(audit_context)
  end
end
