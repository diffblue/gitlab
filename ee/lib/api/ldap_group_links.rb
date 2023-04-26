# frozen_string_literal: true

module API
  class LdapGroupLinks < ::API::Base
    before { authenticate! }

    ldap_group_links_tags = %w[ldap_group_links]

    feature_category :system_access

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
    end
    resource :groups do
      desc 'List LDAP group links' do
        detail 'Get LDAP group links for a group'
        success EE::API::Entities::LdapGroupLink
        is_array true
        tags ldap_group_links_tags
      end
      get ":id/ldap_group_links" do
        group = find_group(params[:id])
        authorize! :admin_group, group

        ldap_group_links = group.ldap_group_links

        if ldap_group_links.present?
          present ldap_group_links, with: EE::API::Entities::LdapGroupLink
        else
          render_api_error!('No linked LDAP groups found', 404)
        end
      end

      desc 'Add LDAP group link with CN or filter' do
        detail 'Adds an LDAP group link using a CN or filter.'\
          'Adding a group link by filter is only supported in the Premium tier and above.'
        success EE::API::Entities::LdapGroupLink
        failure [
          { code: 400, message: 'Validation error' },
          { code: 404, message: 'Not found' },
          { code: 422, message: 'Unprocessable entity' }
        ]
        tags ldap_group_links_tags
      end
      params do
        optional 'cn', type: String, desc: 'The CN of a LDAP group'
        optional 'filter', type: String, desc: 'The LDAP filter for the group'
        requires 'group_access', type: Integer, values: Gitlab::Access.all_values,
          desc: 'Access level for members of the LDAP group'
        requires 'provider', type: String, desc: 'LDAP provider for the LDAP group link'
        exactly_one_of :cn, :filter
      end
      post ":id/ldap_group_links" do
        group = find_group(params[:id])
        authorize! :admin_group, group
        break not_found! if params[:filter] && !group.licensed_feature_available?(:ldap_group_sync_filter)

        ldap_group_link = group.ldap_group_links.new(declared_params(include_missing: false))

        if ldap_group_link.save
          present ldap_group_link, with: EE::API::Entities::LdapGroupLink
        else
          render_api_error!(ldap_group_link.errors.full_messages.first, 409)
        end
      end

      desc 'Delete LDAP group link' do
        detail 'Deletes an LDAP group link. Deprecated. Scheduled for removal in a future release.'
        tags ldap_group_links_tags
      end
      params do
        requires 'cn', type: String, desc: 'The CN of a LDAP group'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete ":id/ldap_group_links/:cn" do
        group = find_group(params[:id])
        authorize! :admin_group, group

        ldap_group_link = group.ldap_group_links.find_by(cn: params[:cn])

        if ldap_group_link
          ldap_group_link.destroy
          no_content!
        else
          render_api_error!('Linked LDAP group not found', 404)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Delete LDAP group link' do
        detail 'Deletes an LDAP group link for a specific LDAP provider.'\
          'Deprecated. Scheduled for removal in a future release.'
        tags ldap_group_links_tags
      end
      params do
        requires 'cn', type: String, desc: 'The CN of a LDAP group'
        requires 'provider', type: String, desc: 'LDAP provider for the LDAP group link'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete ":id/ldap_group_links/:provider/:cn" do
        group = find_group(params[:id])
        authorize! :admin_group, group

        ldap_group_link = group.ldap_group_links.find_by(cn: params[:cn], provider: params[:provider])

        if ldap_group_link
          ldap_group_link.destroy
          no_content!
        else
          render_api_error!('Linked LDAP group not found', 404)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Delete LDAP group link with CN or filter' do
        detail 'Deletes an LDAP group link using a CN or filter.'\
          'Deleting by filter is only supported in the Premium tier and above.'
        tags ldap_group_links_tags
      end
      params do
        optional 'cn', type: String, desc: 'The CN of a LDAP group'
        optional 'filter', type: String, desc: 'The LDAP filter for the group'
        requires 'provider', type: String, desc: 'LDAP provider for the LDAP group link'
        exactly_one_of :cn, :filter
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete ":id/ldap_group_links" do
        group = find_group(params[:id])
        authorize! :admin_group, group
        break not_found! if params[:filter] && !group.licensed_feature_available?(:ldap_group_sync_filter)

        ldap_group_link = group.ldap_group_links.find_by(declared_params(include_missing: false))

        if ldap_group_link
          ldap_group_link.destroy
          no_content!
        else
          render_api_error!('Linked LDAP group not found', 404)
        end
      end
    end
  end
end
