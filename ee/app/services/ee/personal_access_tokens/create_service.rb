# frozen_string_literal: true

module EE
  module PersonalAccessTokens
    module CreateService
      extend ::Gitlab::Utils::Override

      def execute
        super.tap do |response|
          send_audit_event(response)
        end
      end

      private

      def send_audit_event(response)
        message = if response.success?
                    "Created personal access token with id #{response.payload[:personal_access_token].id}"
                  else
                    "Attempted to create personal access token but failed with message: #{response.message}"
                  end

        audit_context = {
          name: 'personal_access_token_created',
          author: current_user,
          scope: current_user,
          target: target_user,
          message: message
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end

      override :creation_permitted?
      def creation_permitted?
        return true if super

        return false unless target_user.service_account?

        return false unless params[:group]

        Ability.allowed?(current_user, :admin_service_accounts, params[:group]) &&
          target_user.provisioned_by_group_id == params[:group].id
      end
    end
  end
end
