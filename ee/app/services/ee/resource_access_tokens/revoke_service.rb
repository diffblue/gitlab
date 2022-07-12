# frozen_string_literal: true

module EE
  module ResourceAccessTokens
    module RevokeService
      def execute
        super.tap do |response|
          audit_event_service(access_token, response)
        end
      end

      private

      def audit_event_service(token, response)
        message = if response.success?
                    "Revoked #{resource.class.name.downcase} access token with token_id: #{token.id}"
                  else
                    "Attempted to revoke #{resource.class.name.downcase} access token with token_id: #{token.id}, " \
                    "but failed with message: #{response.message}"
                  end

        audit_context = {
          name: event_type(response),
          author: current_user,
          scope: resource,
          target: token,
          message: message,
          target_details: token.user.name,
          additional_details: { action: :custom }
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end

      def event_type(response)
        if response.success?
          "#{resource.class.name.downcase}_access_token_deleted"
        else
          "#{resource.class.name.downcase}_access_token_deletion_failed"
        end
      end
    end
  end
end
