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

        def check_access_rights!
          not_found! unless project.product_analytics_enabled?
          unauthorized! unless can?(current_user, :developer_access, project)
        end

        def cube_server_url(endpoint)
          "#{Gitlab::CurrentSettings.cube_api_base_url}/cubejs-api/v1/" + endpoint
        end

        def gitlab_token
          return unless params[:include_token]

          ::ResourceAccessTokens::CreateService.new(
            current_user,
            project,
            { expires_at: 1.day.from_now }).execute.payload[:access_token]&.token
        end

        def cube_security_headers
          payload = {
            iat: Time.now.utc.to_i,
            exp: Time.now.utc.to_i + 180,
            appId: "gitlab_project_#{params[:project_id]}",
            gitlabToken: gitlab_token,
            iss: ::Settings.gitlab.host
          }

          {
            "Content-Type": 'application/json',
            Authorization: JWT.encode(payload, Gitlab::CurrentSettings.cube_api_key, 'HS256')
          }
        end

        def database_exists?(body)
          (body['error'] =~ %r{\AError: Code: (81|60)\..*(UNKNOWN_DATABASE|UNKNOWN_TABLE)}).nil?
        end

        def cube_data_query(load_data)
          check_access_rights!

          response = ::Gitlab::HTTP.post(
            cube_server_url(load_data ? 'load' : 'dry-run'),
            allow_local_requests: true,
            headers: cube_security_headers,
            body: { query: params["query"], "queryType": params["queryType"] }.to_json
          )

          body = Gitlab::Json.parse(response.body)

          if database_exists?(body)
            status :ok

            body
          else
            status :not_found

            not_found!('Clickhouse Database')
          end
        end

        params :cube_query_params do
          requires :project_id, type: Integer, desc: 'ID of the project to query'
          requires :query,
                   type: Hash,
                   desc: "A valid Cube query. See reference documentation: https://cube.dev/docs/query-format"
          optional :queryType,
                   type: String,
                   default: 'multi',
                   desc: 'The query type. Currently only "multi" is supported.'
        end
      end

      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Proxy analytics request to cube installation. Requires :cube_api_proxy flag to be enabled.'
        params do
          use :cube_query_params
        end
        post ':project_id/product_analytics/request/load' do
          cube_data_query(true)
        end

        params do
          use :cube_query_params
        end
        post ':project_id/product_analytics/request/dry-run' do
          cube_data_query(false)
        end

        params do
          requires :project_id, type: Integer, desc: 'ID of the project to get meta data'
        end
        post ':project_id/product_analytics/request/meta' do
          check_access_rights!

          response = ::Gitlab::HTTP.get(
            cube_server_url('meta'),
            allow_local_requests: true,
            headers: cube_security_headers
          )

          status :ok
          Gitlab::Json.parse(response.body)
        end

        desc 'Get a list of defined funnels for a project'
        get ':project_id/product_analytics/funnels' do
          check_access_rights!

          project.product_analytics_funnels.map do |funnel|
            {
              name: funnel.name,
              sql: funnel.to_sql,
              steps: funnel.steps.map(&:step_definition)
            }
          end
        end
      end
    end
  end
end
