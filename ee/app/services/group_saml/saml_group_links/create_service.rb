# frozen_string_literal: true

module GroupSaml
  module SamlGroupLinks
    class CreateService < BaseService
      def initialize(current_user:, group:, params:)
        @current_user = current_user
        @group = group
        @params = params
        @saml_group_link = group.saml_group_links.new
      end

      def execute
        return ServiceResponse.error(message: 'Unauthorized') unless authorized?

        save_saml_group_link
      end

      def save_saml_group_link
        saml_group_link.assign_attributes(params)
        saml_group_link.save ? success : error
      rescue ArgumentError => e
        saml_group_link.errors.add(:base, e.message)
        error
      end

      attr_reader :saml_group_link

      private

      attr_reader :current_user, :group, :params

      def authorized?
        can?(current_user, :admin_saml_group_links, group)
      end

      def success
        create_audit_event
        ServiceResponse.success
      end

      def error
        ServiceResponse.error(message: 'Failed to create SamlGroupLink',
                              payload: { error: saml_group_link.errors.full_messages.join(",") },
                              http_status: 400)
      end

      def create_audit_event
        ::Gitlab::Audit::Auditor.audit(
          name: 'saml_group_links_created',
          author: current_user,
          scope: group,
          target: group,
          message: 'SAML group links created. Group Name - %{group_name}, '\
                   'Access Level - %{access_level}' % { group_name: saml_group_link.saml_group_name,
                                                        access_level: saml_group_link.access_level }
        )
      end
    end
  end
end
