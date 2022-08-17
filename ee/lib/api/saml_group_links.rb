# frozen_string_literal: true

module API
  class SamlGroupLinks < ::API::Base
    before { authenticate! }

    feature_category :authentication_and_authorization

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups do
      desc 'Get SAML group links for a group' do
        success EE::API::Entities::SamlGroupLink
      end
      get ":id/saml_group_links" do
        group = find_group(params[:id])
        unauthorized! unless can?(current_user, :admin_saml_group_links, group)

        saml_group_links = group.saml_group_links

        present saml_group_links, with: EE::API::Entities::SamlGroupLink
      end

      desc 'Add a SAML group link for a group' do
        success EE::API::Entities::SamlGroupLink
      end
      params do
        requires 'saml_group_name', type: String, desc: 'The name of a SAML group'
        requires 'access_level', type: String, desc: 'Access level of a SAML group'
      end
      post ":id/saml_group_links" do
        group = find_group(params[:id])

        unauthorized! unless can?(current_user, :admin_saml_group_links, group)

        service = ::GroupSaml::SamlGroupLinks::CreateService.new(current_user: current_user,
                                                                 group: group,
                                                                 params: declared_params(include_missing: false))
        response = service.execute

        if response.success?
          present service.saml_group_link, with: EE::API::Entities::SamlGroupLink
        else
          render_api_error!(response[:error], response.http_status)
        end
      end

      desc 'Delete an existing SAML Group Link for a group' do
        success EE::API::Entities::SamlGroupLink
      end
      params do
        requires 'saml_group_name', type: String, desc: 'The Name of a SAML group link'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete ":id/saml_group_links/:saml_group_name" do
        group = find_group(params[:id])

        unauthorized! unless can?(current_user, :admin_saml_group_links, group)

        saml_group_link = group.saml_group_links.find_by(saml_group_name: params[:saml_group_name])

        if saml_group_link
          ::GroupSaml::SamlGroupLinks::DestroyService.new(current_user: current_user,
                                                          group: group,
                                                          saml_group_link: saml_group_link)
                                                      .execute
          no_content!
        else
          render_api_error!('Linked SAML group link not found', 404)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
