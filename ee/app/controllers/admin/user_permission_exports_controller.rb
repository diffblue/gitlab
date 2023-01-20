# frozen_string_literal: true

class Admin::UserPermissionExportsController < Admin::ApplicationController
  feature_category :user_profile

  before_action :check_user_permission_export_availability!

  def index
    response = ::UserPermissions::ExportService.new(current_user).csv_data

    respond_to do |format|
      format.csv do
        if response.success?
          stream_csv_headers(csv_filename)

          self.response_body = response.payload
        else
          flash[:alert] = _('Failed to generate report, please try again after sometime')

          redirect_to admin_users_path
        end
      end
    end
  end

  private

  def csv_filename
    "user-permissions-export-#{Time.current.to_i}.csv"
  end

  def check_user_permission_export_availability!
    render_404 unless current_user.can?(:export_user_permissions)
  end
end
