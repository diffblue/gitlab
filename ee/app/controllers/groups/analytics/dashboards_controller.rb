# frozen_string_literal: true

module Groups
  module Analytics
    class DashboardsController < Groups::Analytics::ApplicationController
      before_action :load_group
      before_action { authorize_view_by_action!(:read_group_analytics_dashboards) }

      layout 'group'

      def index; end
    end
  end
end
