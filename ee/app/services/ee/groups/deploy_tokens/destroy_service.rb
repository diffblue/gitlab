# frozen_string_literal: true

module EE
  module Groups
    module DeployTokens
      module DestroyService
        extend ::Gitlab::Utils::Override

        override :execute
        def execute
          super.tap do |deploy_token|
            audit_event_service(deploy_token)
          end
        end

        private

        def audit_event_service(deploy_token)
          message = "Destroyed group deploy token with name: #{deploy_token.name} with token_id: #{deploy_token.id} with scopes: #{deploy_token.scopes}."

          audit_context = {
            name: "group_deploy_token_destroyed",
            author: current_user,
            scope: group,
            target: deploy_token,
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
