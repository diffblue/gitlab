# frozen_string_literal: true

module EE::Projects::EnableDeployKeyService
  extend ActiveSupport::Concern
  extend ::Gitlab::Utils::Override

  override :execute
  def execute
    super.tap do |key|
      break unless key

      log_audit_event(key)
    end
  end

  private

  def log_audit_event(key)
    audit_context = {
      name: 'deploy_key_added',
      author: current_user,
      scope: project,
      target: key,
      message: "Added deploy key",
      additional_details: { add: "deploy_key" }
    }

    ::Gitlab::Audit::Auditor.audit(audit_context)
  end
end
