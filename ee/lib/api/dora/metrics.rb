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
          optional :environment_tier, type: String, desc: "The tier of the environment."
        end

        def fetch!(container)
          result = ::Dora::AggregateMetricsService
            .new(container: container, current_user: current_user, params: declared_params(include_missing: false))
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
