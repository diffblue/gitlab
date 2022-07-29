# frozen_string_literal: true

module Gitlab
  module Insights
    module Executors
      class DoraExecutor
        DoraExecutorError = Class.new(StandardError)

        def initialize(query_params:, current_user:, insights_entity:, projects: {}, chart_type:)
          @query_params = query_params
          @current_user = current_user
          @insights_entity = insights_entity
          @projects = projects
          @chart_type = chart_type
        end

        def execute
          result = Dora::AggregateMetricsService.new(
            container: insights_entity,
            current_user: current_user,
            params: dora_api_params
          ).execute

          raise(DoraExecutorError, result[:message]) if result[:status] == :error

          reduced_data = Gitlab::Insights::Reducers::DoraReducer.reduce(result[:data], period: group_by, metric: metric)
          serializer.present(reduced_data)
        end

        private

        attr_reader :query_params, :current_user, :insights_entity, :projects, :chart_type

        def dora_api_params
          params = {
            interval: dora_interval,
            environment_tiers: environment_tiers,
            start_date: start_date,
            metric: metric
          }

          # AggregateMetricsService filters out projects outside of the group
          if found_projects.present? && insights_entity.is_a?(::Namespace)
            params[:group_project_ids] = found_projects.pluck(:id) # rubocop: disable CodeReuse/ActiveRecord
          end

          params.compact
        end

        def found_projects
          @found_projects ||= Gitlab::Insights::Finders::ProjectsFinder.new(projects).execute
        end

        def environment_tiers
          query_params[:environment_tiers].presence
        end

        def metric
          query_params[:metric] || 'deployment_frequency'
        end

        def start_date
          case group_by
          when 'day'
            period_limit.days.ago.to_date
          when 'month'
            period_limit.months.ago.to_date
          end
        end

        def period_limit
          query_params[:period_limit] || 15
        end

        def dora_interval
          case group_by
          when 'day'
            'daily'
          when 'month'
            'monthly'
          else
            raise DoraExecutorError, "Unknown group_by value is given: #{group_by}"
          end
        end

        def group_by
          query_params[:group_by] || 'day'
        end

        def serializer
          case chart_type
          when 'bar'
            Gitlab::Insights::Serializers::Chartjs::BarSerializer
          else
            raise DoraExecutor::DoraExecutorError, "Unsupported chart type is given: #{chart_type}"
          end
        end
      end
    end
  end
end
