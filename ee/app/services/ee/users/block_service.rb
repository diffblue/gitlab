# frozen_string_literal: true

module EE
  module Users
    module BlockService
      extend ::Gitlab::Utils::Override

      override :after_block_hook
      def after_block_hook(user)
        super

        log_audit_event(user)
      end

      private

      def log_audit_event(user)
        ::Gitlab::Audit::Auditor.audit({
          name: 'user_blocked',
          message: 'Blocked user',
          author: current_user,
          scope: user,
          target: user,
          target_details: user.username
        })
      end
    end
  end
end
