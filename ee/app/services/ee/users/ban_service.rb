# frozen_string_literal: true

module EE
  module Users
    module BanService
      extend ::Gitlab::Utils::Override

      override :update_user
      def update_user(user)
        super.tap do |result|
          log_audit_event(user) if result.present?
        end
      end

      private

      def log_audit_event(user)
        audit_context = {
          name: "ban_user",
          author: current_user,
          scope: user,
          target: user,
          target_details: user.username,
          message: "Banned user"
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end
    end
  end
end
