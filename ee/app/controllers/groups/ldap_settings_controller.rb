# frozen_string_literal: true

class Groups::LdapSettingsController < Groups::ApplicationController
  before_action :group
  before_action :require_ldap_enabled
  before_action :authorize_admin_group!
  before_action :authorize_manage_ldap_settings!

  feature_category :system_access

  def update
    if @group.update(ldap_settings_params)
      redirect_back_or_default(default: group_ldap_group_links_path(@group), options: { notice: _('LDAP settings updated') })
    else
      redirect_back_or_default(default: group_ldap_group_links_path(@group), options: { alert: _('Could not update the LDAP settings') })
    end
  end

  private

  def authorize_manage_ldap_settings!
    render_404 unless Feature.enabled?(:ldap_settings_unlock_groups_by_owners)
    render_404 unless can?(current_user, :admin_ldap_group_settings, group)
  end

  def require_ldap_enabled
    render_404 unless Gitlab::Auth::Ldap::Config.enabled?
  end

  def ldap_settings_params
    attrs = %i[unlock_membership_to_ldap]

    params.require(:group).permit(attrs)
  end
end
