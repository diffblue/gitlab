# frozen_string_literal: true

module EE
  module Users
    module DeactivateService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(user)
        super.tap do |result|
          log_audit_event(user) if result[:status] == :success
        end
      end

      private

      def log_audit_event(user)
        audit_context = {
          name: 'user_deactivate',
          author: current_user,
          scope: user,
          target: user,
          message: "Deactivated user",
          target_details: user.username
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end
    end
  end
end
