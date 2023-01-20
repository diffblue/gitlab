# frozen_string_literal: true

module Groups
  module Analytics
    module CycleAnalytics
      class StagesController < Groups::Analytics::ApplicationController
        include ::Analytics::CycleAnalytics::StageActions
        extend ::Gitlab::Utils::Override

        before_action :validate_params, only: %i[median average records average_duration_chart count]
        before_action :authorize_read_group_stage, only: %i[median average records average_duration_chart count]

        urgency :low

        override :index
        def index
          return render_403 unless can?(current_user, :read_group_cycle_analytics, @group)

          super
        end

        def average_duration_chart
          date_with_value = data_collector
            .duration_chart_average_data
            .each_with_object({}) { |item, hash| hash[item.date] = item.average_duration_in_seconds }

          date_with_value = Gitlab::Analytics::DateFiller.new(date_with_value,
                                                              from: request_params.created_after,
                                                              to: request_params.created_before,
                                                              default_value: nil).fill

          formatted_data = date_with_value.map { |k, v| { date: k, average_duration_in_seconds: v } }

          render json: ::Analytics::CycleAnalytics::DurationChartAverageItemEntity.represent(formatted_data)
        end

        private

        override :parent
        def parent
          @group
        end

        override :value_stream_class
        def value_stream_class
          ::Analytics::CycleAnalytics::ValueStream
        end

        override :all_cycle_analytics_params
        def all_cycle_analytics_params
          super.merge({ group: @group })
        end

        def value_stream
          @value_stream ||= if params[:value_stream_id] && params[:value_stream_id] != ::Analytics::CycleAnalytics::Stages::BaseService::DEFAULT_VALUE_STREAM_NAME
                              @group.value_streams.find(params[:value_stream_id])
                            else
                              super
                            end
        end

        def authorize_read_group_stage
          return render_403 unless can?(current_user, :delete_group_stage, @group)
        end
      end
    end
  end
end
