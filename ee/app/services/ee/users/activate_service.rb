# frozen_string_literal: true

module EE
  module Users
    module ActivateService
      extend ::Gitlab::Utils::Override

      private

      override :after_activate_hook
      def after_activate_hook(user)
        log_audit_event(user)
      end

      def log_audit_event(user)
        audit_context = {
          name: 'user_activate',
          author: current_user,
          scope: user,
          target: user,
          message: "Activated user",
          target_details: user.username
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end
    end
  end
end
