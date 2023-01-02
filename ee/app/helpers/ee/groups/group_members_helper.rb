# frozen_string_literal: true

module EE::Groups::GroupMembersHelper
  extend ::Gitlab::Utils::Override

  override :group_members_list_data
  def group_members_list_data(group, _members, _pagination = {})
    super.merge!({
      disable_two_factor_path: group_two_factor_auth_path(group),
      ldap_override_path: override_group_group_member_path(group, ':id')
    })
  end

  override :group_members_app_data
  def group_members_app_data(group, members:, invited:, access_requests:, banned:, include_relations:, search:)
    super.merge!({
       can_export_members: can?(current_user, :export_group_memberships, group),
       export_csv_path: export_csv_group_group_members_path(group),
       can_filter_by_enterprise: can?(current_user, :admin_group_member, group) && group.root_ancestor.saml_enabled?,
       banned: group_members_list_data(group, banned)
     })
  end

  def group_member_header_subtext(group)
    if ::Namespaces::FreeUserCap.notification_or_enforcement_enabled?(group.root_ancestor) &&
      can?(current_user, :admin_group_member, group.root_ancestor)
      super + member_header_manage_namespace_members_text(group.root_ancestor)
    else
      super
    end
  end
end
