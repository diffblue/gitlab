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

      private

      def check_feature_availability
        render_404 unless group.unique_project_download_limit_enabled?
      end
    end
  end
end
