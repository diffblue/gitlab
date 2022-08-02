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

          audit_context = {
            name: "group_deploy_token_revoked",
            author: current_user,
            scope: group,
            target: token,
            message: message,
            additional_details: {
              action: :custom
            }
          }
          ::Gitlab::Audit::Auditor.audit(audit_context)
        end
      end
    end
  end
end
