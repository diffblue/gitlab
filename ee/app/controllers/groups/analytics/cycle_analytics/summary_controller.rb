# frozen_string_literal: true

module Groups
  module Analytics
    module CycleAnalytics
      class SummaryController < Groups::Analytics::ApplicationController
        extend ::Gitlab::Utils::Override
        include CycleAnalyticsParams

        before_action :authorize_access
        before_action :validate_params

        urgency :low

        def show
          render json: group_level.summary
        end

        def time_summary
          render json: group_level.time_summary
        end

        def lead_times
          data_collector = data_collector_for(::Gitlab::Analytics::CycleAnalytics::Summary::LeadTime)
          render json: ::Analytics::CycleAnalytics::DurationChartAverageItemEntity.represent(data_collector.duration_chart_average_data)
        end

        def cycle_times
          data_collector = data_collector_for(::Gitlab::Analytics::CycleAnalytics::Summary::CycleTime)
          render json: ::Analytics::CycleAnalytics::DurationChartAverageItemEntity.represent(data_collector.duration_chart_average_data)
        end

        private

        def namespace
          @group
        end

        def group_level
          @group_level ||= ::Analytics::CycleAnalytics::GroupLevel.new(group: namespace, options: options(request_params.to_data_collector_params))
        end

        def authorize_access
          return render_403 unless can?(current_user, :read_group_cycle_analytics, namespace)
        end

        def data_collector_for(summary_class)
          group_stage = ::Analytics::CycleAnalytics::Stage.new(namespace: namespace)
          all_params = request_params.to_data_collector_params
          group_stage_with_metadata = summary_class.new(stage: group_stage, current_user: current_user, options: all_params).stage

          Gitlab::Analytics::CycleAnalytics::DataCollector.new(
            stage: group_stage_with_metadata,
            params: all_params
          )
        end
      end
    end
  end
end
