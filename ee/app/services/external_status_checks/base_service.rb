# frozen_string_literal: true

module ExternalStatusChecks
  class BaseService < BaseContainerService
    private

    def with_audit_logged(rule, name, &block)
      audit_context = {
        name: name,
        author: current_user,
        scope: rule.project,
        target: rule
      }

      ::Gitlab::Audit::Auditor.audit(audit_context, &block)
    end
  end
end
