# frozen_string_literal: true

module API
  class MemberRoles < ::API::Base
    before { authenticate! }
    before { authorize_admin_group }
    before { not_found! unless user_group.custom_roles_enabled? }

    feature_category :system_access

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
    end

    resource :groups do
      desc 'Get Member Roles for a group' do
        success EE::API::Entities::MemberRole
        is_array true
        tags ["group_member_roles"]
      end

      get ":id/member_roles" do
        group = find_group(params[:id])
        member_roles = group.member_roles
        present member_roles, with: EE::API::Entities::MemberRole
      end

      desc 'Create Member Role for a group' do
        success EE::API::Entities::MemberRole
        failure [
          code: 400
        ]
        tags ["group_member_roles"]
      end

      params do
        requires(
          'base_access_level',
          type: Integer,
          values: Gitlab::Access.all_values,
          desc: 'Base Access Level for the configured role',
          documentation: { example: 10 }
        )

        ::MemberRole::ALL_CUSTOMIZABLE_PERMISSIONS.each do |permission_name, permission_description|
          optional permission_name.to_s, type: Boolean, desc: permission_description
        end
      end

      post ":id/member_roles" do
        group = find_group(params[:id])

        member_role = group.member_roles.new(declared_params)

        if member_role.save
          present member_role, with: EE::API::Entities::MemberRole
        else
          render_api_error!(member_role.errors.full_messages.first, 400)
        end
      end

      desc 'Delete Member Role for a group' do
        success [
          code: 204
        ]
        failure [
          code: 404, message: 'Member Role not found'
        ]
        tags ["group_member_roles"]
      end

      params do
        requires(
          'member_role_id',
          type: Integer,
          desc: 'The ID of the Member Role to be deleted',
          documentation: { example: 2 }
        )
      end

      delete ":id/member_roles/:member_role_id" do
        group = find_group(params[:id])

        member_role = group.member_roles.find_by_id(params[:member_role_id])

        if member_role
          member_role.destroy
          no_content!
        else
          render_api_error!('Member Role not found', 404)
        end
      end
    end
  end
end
