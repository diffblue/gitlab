# frozen_string_literal: true

module Groups
  module Settings
    class ReportingController < Groups::ApplicationController
      layout 'group_settings'

      before_action :check_feature_availability
      before_action :authorize_admin_group!

      feature_category :insider_threat
      urgency :low

      def show
      end

      def update
        if Groups::UpdateService.new(@group, current_user, group_params).execute
          notice = "Group '#{@group.name}' was successfully updated."

          redirect_to group_settings_reporting_path(@group), notice: notice
        else
          render action: "show"
        end
      end

      private

      def group_params
        params.require(:group).permit(%i[
          unique_project_download_limit
          unique_project_download_limit_interval
        ])
      end

      def check_feature_availability
        render_404 unless group.unique_project_download_limit_enabled?
      end
    end
  end
end
