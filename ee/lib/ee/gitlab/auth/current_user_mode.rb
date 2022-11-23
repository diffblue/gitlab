# frozen_string_literal: true

module EE
  module Gitlab
    module Auth
      module CurrentUserMode
        extend ::Gitlab::Utils::Override

        private

        override :audit_user_enable_admin_mode
        def audit_user_enable_admin_mode
          audit_context = {
            name: 'user_enable_admin_mode',
            author: user,
            scope: user,
            target: user,
            message: 'Enabled admin mode',
            created_at: DateTime.current
          }

          ::Gitlab::Audit::Auditor.audit(audit_context)
        end
      end
    end
  end
end
