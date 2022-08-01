# frozen_string_literal: true

module GroupSaml
  module SamlGroupLinks
    class DestroyService < BaseService
      def initialize(current_user:, group:, saml_group_link:)
        @current_user = current_user
        @group = group
        @saml_group_link = saml_group_link
      end

      def execute
        return ServiceResponse.error(message: 'Unauthorized') unless authorized?

        destroy_saml_group_link
      end

      def destroy_saml_group_link
        saml_group_link.destroy
        create_audit_event
        ServiceResponse.success
      end

      private

      attr_reader :current_user, :group, :saml_group_link

      def authorized?
        can?(current_user, :admin_saml_group_links, group)
      end

      def create_audit_event
        ::Gitlab::Audit::Auditor.audit(
          name: 'saml_group_links_removed',
          author: current_user,
          scope: group,
          target: group,
          message: "SAML group links removed. Group Name - #{saml_group_link.saml_group_name}"
        )
      end
    end
  end
end
