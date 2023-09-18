# frozen_string_literal: true

module Projects
  module Settings
    class AnalyticsController < Projects::ApplicationController
      layout 'project_settings'
      feature_category :product_analytics_visualization

      before_action :authorize_analytics_settings!

      def update
        # clear instrumentation key since old one is not valid anymore
        # a new instrumentation key will be set during stack initialization
        params_to_update = update_params.to_h
          .deep_merge({ project_setting_attributes: { product_analytics_instrumentation_key: nil } })

        ::Projects::UpdateService.new(project, current_user, params_to_update).tap do |service|
          result = service.execute
          if result[:status] == :success
            flash[:toast] =
              format(s_("Analytics|Analytics settings for '%{project_name}' were successfully updated."),
                project_name: project.name)

            redirect_to project_settings_analytics_path(project)
          else
            redirect_to project_settings_analytics_path(project), alert: result[:message]
          end
        end
      end

      private

      def update_params
        params.require(:project).permit(*permitted_project_params)
      end

      def permitted_project_params
        [
          project_setting_attributes: [
            :product_analytics_configurator_connection_string, :product_analytics_data_collector_host,
            :cube_api_base_url, :cube_api_key
          ],
          analytics_dashboards_pointer_attributes: [:target_project_id]
        ]
      end

      def authorize_analytics_settings!
        access_denied! unless Feature.enabled?(:combined_analytics_dashboards, project)
      end
    end
  end
end
