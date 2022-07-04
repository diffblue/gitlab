# frozen_string_literal: true

module API
  module Dora
    class Metrics < ::API::Base
      feature_category :continuous_delivery
      urgency :low

      helpers do
        params :dora_metrics_params do
          requires :metric, type: String, desc: 'The metric type.'
          optional :start_date, type: Date, desc: 'Date range to start from.'
          optional :end_date, type: Date, desc: 'Date range to end at.'
          optional :interval, type: String, desc: "The bucketing interval."
          optional :environment_tier,
                   type: String,
                   desc: "The tier of the environment. Deprecated, please use `environment_tiers` param."
          optional :environment_tiers, type: Array[String], desc: "Filter by environment tiers."
        end

        def fetch!(container)
          # Backwards compatibility until %16.0
          params = declared_params(include_missing: false)
          if params[:environment_tier]
            params[:environment_tiers] ||= []
            params[:environment_tiers] |= [params[:environment_tier]]
          end

          result = ::Dora::AggregateMetricsService
            .new(container: container, current_user: current_user, params: params)
            .execute

          if result[:status] == :success
            present result[:data]
          else
            render_api_error!(result[:message], result[:http_status])
          end
        end
      end

      params do
        requires :id, type: String, desc: 'The ID of the project'
      end
      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        namespace ':id/dora/metrics' do
          desc 'Fetch the project-level DORA metrics'
          params do
            use :dora_metrics_params
          end
          get do
            fetch!(user_project)
          end
        end
      end

      params do
        requires :id, type: String, desc: 'The ID of the group'
      end
      resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        namespace ':id/dora/metrics' do
          desc 'Fetch the group-level DORA metrics'
          params do
            use :dora_metrics_params
          end
          get do
            fetch!(user_group)
          end
        end
      end
    end
  end
end
