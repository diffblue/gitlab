# frozen_string_literal: true

module EE
  module Groups
    module DeployTokens
      module RevokeService
        extend ::Gitlab::Utils::Override

        override :execute
        def execute
          super.tap { log_audit_event }
        end

        private

        def log_audit_event
          message = "Revoked group deploy token with name: #{token.name} with token_id: #{token.id} with scopes: #{token.scopes}."

          ::AuditEventService.new(
            current_user,
            group,
            target_id: token.id,
            target_type: token.class.name,
            target_details: token.name,
            action: :custom,
            custom_message: message
          ).security_event
        end
      end
    end
  end
end
