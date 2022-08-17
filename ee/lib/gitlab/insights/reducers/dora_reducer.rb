# frozen_string_literal: true

module Gitlab
  module Insights
    module Reducers
      class DoraReducer < BaseReducer
        def initialize(data, period:, metric:)
          @data = data
          @period = period
          @metric = metric
        end

        def reduce
          data.reverse_each.each_with_object({}) do |item, hash|
            hash[format_date(item['date'])] = format_value(item['value'])
          end
        end

        private

        attr_reader :data, :period, :metric

        def format_date(date)
          Date.parse(date).strftime(period_format)
        end

        def period_format
          case period
          when 'day'
            '%d %b %y'
          when 'month'
            '%B %Y'
          else
            raise Gitlab::Insights::Executors::DoraExecutor::DoraExecutorError, "Unknown period is given: #{period}"
          end
        end

        def format_value(value)
          case metric
          when 'lead_time_for_changes', 'time_to_restore_service'
            value ? value.fdiv(1.day).round(1) : nil
          when 'deployment_frequency'
            value
          when 'change_failure_rate'
            value ? (value * 100).round(2) : 0
          else
            raise Gitlab::Insights::Executors::DoraExecutor::DoraExecutorError, "Unknown metric is given: #{period}"
          end
        end
      end
    end
  end
end
