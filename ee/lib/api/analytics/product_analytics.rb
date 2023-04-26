# frozen_string_literal: true

module API
  module Analytics
    class ProductAnalytics < ::API::Base
      before do
        authenticate!
      end

      feature_category :product_analytics
      urgency :low

      helpers do
        def project
          @project ||= find_project!(params[:project_id])
        end

        def render_response(response)
          if response.success?
            status :ok
            response.payload
          else
            render_api_error!(response.message, response.reason)
          end
        end

        def cube_data_query(load_data)
          params = declared_params(include_missing: false).merge(path: load_data ? 'load' : 'dry-run')

          response = ::ProductAnalytics::CubeDataQueryService.new(
            container: project, current_user: current_user, params: params
          ).execute

          render_response(response)
        end

        def funnel_data
          project.product_analytics_funnels.map do |funnel|
            {
              name: funnel.name,
              sql: funnel.to_sql,
              steps: funnel.steps.map(&:step_definition)
            }
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
          optional :include_token,
            type: Boolean,
            default: false,
            desc: 'Whether to include the access token in the response. (Only required for funnel generation.)'
        end
      end

      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Proxy analytics request to cube installation.
                        Requires :product_analytics_dashboards flag to be enabled.'
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
          params = declared_params(include_missing: false).merge(path: 'meta')

          response = ::ProductAnalytics::CubeDataQueryService.new(
            container: project, current_user: current_user, params: params
          ).execute
          render_response(response)
        end

        desc 'Get a list of defined funnels for a project'
        get ':project_id/product_analytics/funnels' do
          response = ::ProductAnalytics::CubeDataQueryService.new(
            container: project, current_user: current_user, params: { path: 'funnels' }
          ).cannot_query_data?

          if response
            render_response(response)
          else
            funnel_data
          end
        end
      end
    end
  end
end
