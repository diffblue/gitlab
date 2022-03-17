# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module Summary
        class LeadTimeForChanges < BaseTime
          def initialize(stage:, current_user:, options:)
            @stage = stage
            @current_user = current_user
            @options = options
            @from = options[:from].to_date
            @to = (options[:to] || Date.today).to_date
          end

          def title
            s_('CycleAnalytics|Lead Time for Changes')
          end

          def value
            @value ||= dora_lead_time_for_changes
          end

          def unit
            n_('day', 'days', value)
          end

          private

          attr_reader :stage, :current_user, :options, :from, :to

          def dora_lead_time_for_changes
            params = {
              start_date: from,
              end_date: to,
              interval: 'all',
              environment_tier: 'production',
              metric: 'lead_time_for_changes'
            }

            params[:group_project_ids] = options[:projects] if options[:projects].present?

            result = Dora::AggregateMetricsService.new(
              container: stage.parent,
              current_user: current_user,
              params: params
            ).execute

            return convert_to_days(result[:data]) if result[:status] == :success

            # this signals the summary class to not even try to serialize the result
            nil
          end

          def convert_to_days(median_seconds)
            return Gitlab::CycleAnalytics::Summary::Value::None.new if median_seconds.to_i == 0

            median_days = median_seconds.fdiv(1.day).round(1)

            Gitlab::CycleAnalytics::Summary::Value::Numeric.new(median_days)
          end
        end
      end
    end
  end
end
