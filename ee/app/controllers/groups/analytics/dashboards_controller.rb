# frozen_string_literal: true

module Groups
  module Analytics
    class DashboardsController < Groups::Analytics::ApplicationController
      before_action { authorize_view_by_action!(:read_group_analytics_dashboards) }

      layout 'group'

      MAX_ALLOWED_PATHS = 4

      def index
        @namespaces =
          if params[:query].present?
            paths_array = params[:query].split(",").first(MAX_ALLOWED_PATHS)
            sources = Route.inside_path(@group.full_path).where(path: paths_array).map(&:source) # rubocop:disable CodeReuse/ActiveRecord

            sources.map do |source|
              {
                name: source.name,
                full_path: source.full_path,
                is_project: project?(source)
              }
            end
          else
            []
          end
      end

      private

      def project?(source)
        source.model_name.param_key == "project"
      end
    end
  end
end
