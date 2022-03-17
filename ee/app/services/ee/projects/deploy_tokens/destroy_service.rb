# frozen_string_literal: true

module EE
  module Projects
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
          message = "Destroyed project deploy token with name: #{deploy_token.name} with token_id: #{deploy_token.id} with scopes: #{deploy_token.scopes}."

          ::AuditEventService.new(
            current_user,
            project,
            target_id: deploy_token.id,
            target_type: deploy_token.class.name,
            target_details: deploy_token.name,
            action: :custom,
            custom_message: message
          ).security_event
        end
      end
    end
  end
end
