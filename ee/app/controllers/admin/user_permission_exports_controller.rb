# frozen_string_literal: true

class Admin::UserPermissionExportsController < Admin::ApplicationController
  feature_category :users

  before_action :check_user_permission_export_availability!

  def index
    ::Admin::MembershipsMailer.instance_memberships_export(requested_by: current_user).deliver_later

    flash[:success] = _('Report is generating and will be sent to your email address.')

    redirect_to admin_users_path
  end

  private

  def check_user_permission_export_availability!
    render_404 unless current_user.can?(:export_user_permissions)
  end
end
