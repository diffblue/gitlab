# frozen_string_literal: true

module API
  class AlertManagementAlerts < ::API::Base
    feature_category :incident_management

    params do
      requires :id, type: String, desc: 'The ID of a project'
      requires :alert_iid, type: Integer, desc: 'The IID of the Alert'
    end

    resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      namespace ':id/alert_management_alerts/:alert_iid/metric_images' do
        desc 'Metric Images for alert'
        get do
          alert = find_project_alert(params[:alert_iid])

          if can?(current_user, :read_alert_management_metric_image, alert)
            present alert.metric_images.order_created_at_asc, with: Entities::MetricImage
          else
            render_api_error!('Alert not found', 404)
          end
        end
      end
    end

    helpers do
      def find_project_alert(iid, project_id = nil)
        project = project_id ? find_project!(project_id) : user_project

        ::AlertManagement::AlertsFinder.new(current_user, project, { iid: [iid] }).execute.first
      end
    end
  end
end
