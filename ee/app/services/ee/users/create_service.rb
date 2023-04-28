# frozen_string_literal: true

module EE
  module Users
    module CreateService
      extend ::Gitlab::Utils::Override

      override :after_create_hook
      def after_create_hook(user, reset_token)
        super

        log_audit_event(user) if audit_required?
      end

      private

      def log_audit_event(user)
        ::Gitlab::Audit::Auditor.audit({
          name: "user_created",
          author: current_user,
          scope: user,
          target: user,
          target_details: user.full_path,
          message: "User #{user.username} created",
          additional_details: {
            add: "user"
          }
        })
      end

      def audit_required?
        current_user.present?
      end
    end
  end
end
