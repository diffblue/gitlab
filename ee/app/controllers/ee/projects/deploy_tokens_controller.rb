# frozen_string_literal: true

module EE
  module Projects
    module DeployTokensController
      extend ::Gitlab::Utils::Override

      override :revoke
      def revoke
        super

        log_audit_event
      end

      private

      def log_audit_event
        # rubocop:disable Gitlab/ModuleWithInstanceVariables
        message = "Revoked project deploy token with name: #{@token.name} with token_id: #{@token.id} with scopes: #{@token.scopes}."

        ::AuditEventService.new(
          current_user,
          @project,
          target_id: @token.id,
          target_type: @token.class.name,
          target_details: @token.name,
          action: :custom,
          custom_message: message
        ).security_event
        # rubocop:enable Gitlab/ModuleWithInstanceVariables
      end
    end
  end
end
