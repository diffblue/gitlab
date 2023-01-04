# frozen_string_literal: true
module ProtectedEnvironments
  class CreateService < ProtectedEnvironments::BaseService
    def execute
      container.protected_environments.create(sanitized_params).tap do |protected_environment|
        log_audit_event(protected_environment) if protected_environment.persisted?
      end
    end

    private

    def log_audit_event(protected_environment)
      message = if group_container?
                  "Protected environments of #{protected_environment.name} tier"
                else
                  "Protected an environment: #{protected_environment.name}"
                end

      audit_context = {
        name: 'environment_protected',
        author: current_user,
        scope: container,
        target: protected_environment,
        message: message
      }

      ::Gitlab::Audit::Auditor.audit(audit_context)
    end
  end
end
