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
          not_found! unless Gitlab::CurrentSettings.cube_api_base_url.present?
          not_found! unless Gitlab::CurrentSettings.cube_api_key.present?
        end
      end

      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Proxy request to cube installation'
        post ':project_id/product_analytics/request' do
          not_found! unless ::Feature.enabled?(:cube_api_proxy, project)
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
            body: { "query" => params["query"] }.to_json
          )

          Gitlab::Json.parse(response.body)
        end
      end
    end
  end
end
