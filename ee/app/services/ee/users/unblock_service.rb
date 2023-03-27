# frozen_string_literal: true

module EE
  module Users
    module UnblockService
      extend ::Gitlab::Utils::Override

      override :after_unblock_hook
      def after_unblock_hook(user)
        super
        log_audit_event(user)
      end

      private

      def log_audit_event(user)
        audit_context = {
          name: 'unblock_user',
          author: current_user,
          scope: user,
          target: user,
          message: "Unblocked user",
          target_details: user.username
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end
    end
  end
end
