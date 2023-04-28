# frozen_string_literal: true

module EE
  module Users
    module ApproveService
      extend ::Gitlab::Utils::Override

      private

      override :after_approve_hook
      def after_approve_hook(user)
        super

        log_audit_event(user)
      end

      def log_audit_event(user)
        ::Gitlab::Audit::Auditor.audit({
          name: 'user_approved',
          message: _('Instance access request approved'),
          author: current_user,
          scope: user,
          target: user,
          target_details: user.username
        })
      end
    end
  end
end
