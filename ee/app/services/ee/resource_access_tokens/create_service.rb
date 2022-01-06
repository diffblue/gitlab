# frozen_string_literal: true

module EE
  module ResourceAccessTokens
    module CreateService
      def execute
        super.tap do |response|
          audit_event_service(response.payload[:access_token], response)
        end
      end

      private

      def success_message(token)
        if resource_type == 'project'
          "Created project access token with token_id: #{token.id} with scopes: #{token.scopes} and #{resource.member(token.user).human_access} access level."
        else
          "Created #{resource_type} token with token_id: #{token.id} with scopes: #{token.scopes}."
        end
      end

      def audit_event_service(token, response)
        message = if response.success?
                    success_message(token)
                  else
                    "Attempted to create #{resource_type} access token but failed with message: #{response.message}"
                  end

        ::AuditEventService.new(
          current_user,
          resource,
          target_id: token&.id,
          target_type: token&.class&.name,
          target_details: token&.user&.name,
          action: :custom,
          custom_message: message
        ).security_event
      end
    end
  end
end
