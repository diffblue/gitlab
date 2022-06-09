# frozen_string_literal: true

module EE
  module Projects
    module DeployTokens
      module CreateService
        extend ::Gitlab::Utils::Override

        override :execute
        def execute
          super.tap do |result|
            audit_event_service(result[:deploy_token], result)
          end
        end

        private

        def audit_event_service(deploy_token, result)
          if result[:status] == :success
            message = "Created project deploy token with name: #{deploy_token.name} with token_id: #{deploy_token.id} with scopes: #{deploy_token.scopes}."
            name = "deploy_token_created"
          else
            message = "Attempted to create project deploy token but failed with message: #{result[:message]}"
            name = "deploy_token_creation_failed"
          end

          audit_context = {
            name: name,
            author: current_user,
            scope: project,
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
