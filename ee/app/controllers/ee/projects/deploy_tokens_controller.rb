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
        audit_context = {
          name: 'deploy_token_revoked',
          author: current_user,
          scope: @project,
          target: @token,
          message: message,
          additional_details: {
            action: :custom
          }
        }
        ::Gitlab::Audit::Auditor.audit(audit_context)
        # rubocop:enable Gitlab/ModuleWithInstanceVariables
      end
    end
  end
end
