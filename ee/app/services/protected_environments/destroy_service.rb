# frozen_string_literal: true
module ProtectedEnvironments
  class DestroyService < BaseService
    def execute(protected_environment)
      protected_environment.destroy.tap do |protected_environment|
        log_audit_event(protected_environment) if protected_environment.destroyed?
      end
    end

    private

    def log_audit_event(protected_environment)
      message = if group_container?
                  "Unprotected environments of #{protected_environment.name} tier"
                else
                  "Unprotected an environment: #{protected_environment.name}"
                end

      audit_context = {
        name: 'environment_unprotected',
        author: current_user,
        scope: container,
        target: protected_environment,
        message: message
      }

      ::Gitlab::Audit::Auditor.audit(audit_context)
    end
  end
end
