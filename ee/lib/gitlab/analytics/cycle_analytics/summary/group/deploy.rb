# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module Summary
        module Group
          class Deploy < Group::Base
            include Gitlab::CycleAnalytics::GroupProjectsProvider

            def title
              n_('Deploy', 'Deploys', value.to_i)
            end

            def identifier
              :deploys
            end

            def value
              @value ||= ::Gitlab::CycleAnalytics::Summary::Value::PrettyNumeric.new(deployments_count)
            end

            private

            def deployments_count
              result = Dora::AggregateMetricsService.new(
                container: group,
                current_user: options[:current_user],
                params: dora_aggregate_metrics_params
              ).execute_without_authorization

              return 0 unless result[:status] == :success

              result[:data].first['deployment_count'] || 0
            end

            def dora_aggregate_metrics_params
              params = {
                start_date: options[:from].to_date,
                end_date: (options[:to] || Date.today).to_date,
                interval: 'all',
                environment_tiers: %w[production],
                metrics: ['deployment_frequency']
              }

              params[:group_project_ids] = options[:projects] if options[:projects].present?

              params
            end
          end
        end
      end
    end
  end
end
