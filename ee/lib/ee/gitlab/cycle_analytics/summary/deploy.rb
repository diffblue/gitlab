# frozen_string_literal: true

module EE
  module Gitlab
    module CycleAnalytics
      module Summary
        module Deploy
          extend ::Gitlab::Utils::Override

          private

          override :deployments_count
          def deployments_count
            if project.licensed_feature_available?(:cycle_analytics_for_projects)
              deployment_count_via_dora_api
            else
              super
            end
          end

          def deployment_count_via_dora_api
            result = Dora::AggregateMetricsService.new(
              container: project,
              current_user: options[:current_user],
              params: dora_aggregate_metrics_params
            ).execute_without_authorization

            return 0 unless result[:status] == :success

            result[:data].first['deployment_count'] || 0
          end

          def dora_aggregate_metrics_params
            {
              start_date: options[:from].to_date,
              end_date: (options[:to] || Date.today).to_date,
              interval: 'all',
              environment_tiers: %w[production],
              metrics: ['deployment_frequency']
            }
          end
        end
      end
    end
  end
end
