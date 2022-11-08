# frozen_string_literal: true

module API
  module Analytics
    class ProductAnalytics < ::API::Base
      before do
        authenticate!
        check_application_settings!
      end

      feature_category :product_analytics
      urgency :low

      helpers do
        def project
          @project ||= find_project!(params[:project_id])
        end

        def check_application_settings!
          not_found! unless Gitlab::CurrentSettings.product_analytics_enabled?
          not_found! unless Gitlab::CurrentSettings.cube_api_base_url.present?
          not_found! unless Gitlab::CurrentSettings.cube_api_key.present?
        end
      end

      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Proxy analytics request to cube installation. Requires :cube_api_proxy flag to be enabled.'
        params do
          requires :project_id, type: Integer, desc: 'ID of the project to query'
          requires :query,
                   type: String,
                   desc: "A valid Cube query. See reference documentation: https://cube.dev/docs/query-format"
          optional :queryType, type: 'String',
                               default: 'multi',
                               desc: 'The query type. Currently only "multi" is supported.'
        end
        post ':project_id/product_analytics/request/load' do
          not_found! unless project.product_analytics_enabled?
          unauthorized! unless can?(current_user, :developer_access, project)

          payload = {
            iat: Time.now.utc.to_i,
            exp: Time.now.utc.to_i + 180,
            appId: "gitlab_project_#{params[:project_id]}",
            iss: ::Settings.gitlab.host
          }

          response = ::Gitlab::HTTP.post(
            "#{Gitlab::CurrentSettings.cube_api_base_url}/cubejs-api/v1/load",
            allow_local_requests: true,
            headers: {
              "Content-Type": 'application/json',
              Authorization: JWT.encode(payload, Gitlab::CurrentSettings.cube_api_key, 'HS256')
            },
            body: { query: params["query"], "queryType": params["queryType"] }.to_json
          )

          Gitlab::Json.parse(response.body)
        end
      end
    end
  end
end
