# frozen_string_literal: true

module API
  class SamlGroupLinks < ::API::Base
    before { authenticate! }

    SAML_GROUP_LINKS = %w[saml_group_links].freeze

    feature_category :system_access

    params do
      requires :id, types: [String, Integer], desc: 'ID or URL-encoded path of the group'
    end
    resource :groups do
      desc 'Lists SAML group links' do
        detail 'Get SAML group links for a group'
        success EE::API::Entities::SamlGroupLink
        is_array true
        tags SAML_GROUP_LINKS
      end
      get ":id/saml_group_links" do
        group = find_group(params[:id])
        unauthorized! unless can?(current_user, :admin_saml_group_links, group)

        saml_group_links = group.saml_group_links

        present saml_group_links, with: EE::API::Entities::SamlGroupLink
      end

      desc 'Add SAML group link' do
        detail 'Add a SAML group link for a group'
        success EE::API::Entities::SamlGroupLink
        failure [
          { code: 400, message: 'Validation error' },
          { code: 404, message: 'Not found' },
          { code: 422, message: 'Unprocessable entity' }
        ]
        tags SAML_GROUP_LINKS
      end
      params do
        requires 'saml_group_name', type: String, desc: 'The name of a SAML group'
        requires 'access_level', type: Integer, values: Gitlab::Access.all_values,
          desc: 'Level of permissions for the linked SA group'
      end
      post ":id/saml_group_links" do
        group = find_group(params[:id])

        unauthorized! unless can?(current_user, :admin_saml_group_links, group)

        service = ::GroupSaml::SamlGroupLinks::CreateService.new(
          current_user: current_user,
          group: group,
          params: declared_params(include_missing: false)
        )
        response = service.execute

        if response.success?
          present service.saml_group_link, with: EE::API::Entities::SamlGroupLink
        else
          render_api_error!(response[:error], response.http_status)
        end
      end

      desc 'Get SAML group link' do
        detail 'Get a SAML group link for the group'
        success EE::API::Entities::SamlGroupLink
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags SAML_GROUP_LINKS
      end
      params do
        requires 'saml_group_name', type: String, desc: 'Name of an SAML group'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      get ":id/saml_group_links/:saml_group_name" do
        group = find_group(params[:id])

        unauthorized! unless can?(current_user, :admin_saml_group_links, group)

        saml_group_link = group.saml_group_links.find_by(saml_group_name: params[:saml_group_name])

        if saml_group_link
          present saml_group_link, with: EE::API::Entities::SamlGroupLink
        else
          render_api_error!('Linked SAML group link not found', 404)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Delete SAML group link' do
        detail 'Deletes a SAML group link for the group'
        success EE::API::Entities::SamlGroupLink
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags SAML_GROUP_LINKS
      end
      params do
        requires 'saml_group_name', type: String, desc: 'Name of a SAML group'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete ":id/saml_group_links/:saml_group_name" do
        group = find_group(params[:id])

        unauthorized! unless can?(current_user, :admin_saml_group_links, group)

        saml_group_link = group.saml_group_links.find_by(saml_group_name: params[:saml_group_name])

        if saml_group_link
          ::GroupSaml::SamlGroupLinks::DestroyService.new(
            current_user: current_user, group: group, saml_group_link: saml_group_link
          ).execute
          no_content!
        else
          render_api_error!('Linked SAML group link not found', 404)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
