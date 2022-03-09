# frozen_string_literal: true

module EE
  module Groups
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
          message = if result[:status] == :success
                      "Created group deploy token with name: #{deploy_token.name} with token_id: #{deploy_token.id} with scopes: #{deploy_token.scopes}."
                    else
                      "Attempted to create group deploy token but failed with message: #{result[:message]}"
                    end

          ::AuditEventService.new(
            current_user,
            group,
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
