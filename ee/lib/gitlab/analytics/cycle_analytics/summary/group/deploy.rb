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

            def value
              @value ||= ::Gitlab::CycleAnalytics::Summary::Value::PrettyNumeric.new(deployments_count)
            end

            private

            def deployments_count
              @deployments_count ||= if Feature.enabled?(:dora_deployment_frequency_in_vsa, default_enabled: :yaml)
                                       deployment_count_via_dora_api
                                     else
                                       deployment_count_via_finder
                                     end
            end

            # rubocop: disable CodeReuse/ActiveRecord
            def deployment_count_via_finder
              deployments = DeploymentsFinder
                .new(group: group, finished_after: options[:from], finished_before: options[:to], status: :success, order_by: :finished_at)
                .execute

              deployments = deployments.where(project_id: options[:projects]) if options[:projects].present?
              deployments.count
            end
            # rubocop: enable CodeReuse/ActiveRecord

            def deployment_count_via_dora_api
              result = Dora::AggregateMetricsService.new(
                container: group,
                current_user: options[:current_user],
                params: dora_aggregate_metrics_params
              ).execute_without_authorization

              result[:status] == :success ? (result[:data] || 0) : 0
            end

            def dora_aggregate_metrics_params
              params = {
                start_date: options[:from].to_date,
                end_date: (options[:to] || Date.today).to_date,
                interval: 'all',
                environment_tier: 'production',
                metric: 'deployment_frequency'
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
