# frozen_string_literal: true

module API
  class ProviderIdentity < ::API::Base
    include ::Gitlab::Utils::StrongMemoize

    before { authenticate! }
    before { authorize_admin_group }

    feature_category :system_access

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups do
      %w[saml scim].each do |provider_type|
        resource ":id/#{provider_type}", requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          desc 'Get user identities for the provider' do
            success EE::API::Entities::IdentityDetail
          end

          get "/identities" do
            group = find_group(params[:id])

            case provider_type
            when 'saml'
              bad_request! unless group.saml_provider
              present group.saml_provider.identities, with: EE::API::Entities::IdentityDetail
            when 'scim'
              present group.scim_identities, with: EE::API::Entities::IdentityDetail
            end
          end

          desc 'Get a single identity for a user' do
            success EE::API::Entities::IdentityDetail
          end
          params do
            requires :uid, type: String, desc: 'External UID of the user'
          end
          get ':uid', format: false, requirements: { uid: API::NO_SLASH_URL_PART_REGEX } do
            group = find_group(params[:id])
            identity = find_provider_identity(provider_type, params[:uid], group)

            not_found!('Identity') unless identity

            present identity, with: EE::API::Entities::IdentityDetail
          end

          desc 'Update extern_uid for the user' do
            success EE::API::Entities::IdentityDetail
          end

          params do
            requires :uid, type: String, desc: "Current external UID of the user"
            requires :extern_uid, type: String, desc: "Desired/new external UID of the user"
          end

          patch ':uid', format: false, requirements: { uid: API::NO_SLASH_URL_PART_REGEX } do
            group = find_group(params[:id])
            identity = find_provider_identity(provider_type, params[:uid], group)

            not_found!('Identity') unless identity

            if identity.update(extern_uid: params[:extern_uid])
              present identity, with: EE::API::Entities::IdentityDetail
            else
              render_api_error!(identity.errors.full_messages.join(",").to_s, 400)
            end
          end

          desc 'Delete the Provider identity' do
            success EE::API::Entities::IdentityDetail
          end

          params do
            requires :uid, type: String, desc: "Current external UID of the user"
          end

          delete ':uid', format: false, requirements: { uid: API::NO_SLASH_URL_PART_REGEX } do
            group = find_group(params[:id])
            identity = find_provider_identity(provider_type, params[:uid], group)

            not_found!('Identity') unless identity

            identity.delete
            no_content!
          end
        end
      end
    end

    helpers do
      def find_provider_identity(provider_type, extern_uid, group)
        case provider_type
        when 'scim'
          group.scim_identities.with_extern_uid(extern_uid).first
        when 'saml'
          GroupSamlIdentityFinder.find_by_group_and_uid(group: group, uid: extern_uid)
        end
      end
    end
  end
end
