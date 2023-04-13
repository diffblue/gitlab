# frozen_string_literal: true

module Gitlab
  module Insights
    module Executors
      class DoraExecutor
        DoraExecutorError = Class.new(StandardError)
        FORMATTERS = {
          'day' => '%d %b %y',
          'month' => '%B %Y'
        }.freeze
        DEFAULT_VALUES = {
          'deployment_frequency' => 0
        }.freeze

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

          serializer.present(format_data(result[:data]))
        end

        private

        attr_reader :query_params, :current_user, :insights_entity, :projects, :chart_type

        def format_data(data)
          input = data.each_with_object({}) { |item, hash| hash[item['date']] = format_value(item[metric]) }

          Gitlab::Analytics::DateFiller.new(input,
                                            from: start_date,
                                            to: Date.today,
                                            period: group_by.to_sym,
                                            default_value: DEFAULT_VALUES[metric],
                                            date_formatter: -> (date) { date.strftime(FORMATTERS[group_by]) }
                                           ).fill
        end

        def format_value(value)
          case metric
          when 'lead_time_for_changes', 'time_to_restore_service'
            value ? value.fdiv(1.day).round(1) : nil
          when 'change_failure_rate'
            value ? (value * 100).round(2) : 0
          when 'deployment_frequency'
            value ? value.round(2) : 0
          else
            value
          end
        end

        def dora_api_params
          params = {
            interval: dora_interval,
            environment_tiers: environment_tiers,
            start_date: start_date,
            metrics: [metric]
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
            (period_limit - 1).days.ago.to_date
          when 'month'
            (period_limit - 1).months.ago.to_date
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
          unless %w[bar line].include?(chart_type)
            raise DoraExecutor::DoraExecutorError, "Unsupported chart type is given: #{chart_type}"
          end

          Gitlab::Insights::Serializers::Chartjs::BarSerializer
        end
      end
    end
  end
end
