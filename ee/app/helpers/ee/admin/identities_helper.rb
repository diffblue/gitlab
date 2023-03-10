# frozen_string_literal: true
module EE
  module Admin
    module IdentitiesHelper
      extend ::Gitlab::Utils::Override

      override :provider_id_cell_testid
      def provider_id_cell_testid(identity)
        return super unless identity.saml_provider_id

        "provider_id_#{identity.saml_provider_id}"
      end

      override :provider_id
      def provider_id(identity)
        return super unless identity.saml_provider_id

        identity.saml_provider_id
      end

      override :saml_group_cell_testid
      def saml_group_cell_testid(identity)
        return super unless identity.saml_provider

        nil
      end

      override :saml_group_link
      def saml_group_link(identity)
        return super unless identity.saml_provider

        link_to identity.saml_provider.group.path, identity.saml_provider.group
      end

      def identity_cells_to_render?(identities, user)
        super || user.scim_identities.present?
      end

      override :scim_identities_collection
      def scim_identities_collection(user)
        user.scim_identities
      end

      def scim_group_link(scim_identity)
        return '-' unless scim_identity.group

        link_to scim_identity.group.path, scim_identity.group
      end
    end
  end
end
