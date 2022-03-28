# frozen_string_literal: true

module EE
  module Analytics
    module CycleAnalytics
      module Stages
        module ListService
          extend ::Gitlab::Utils::Override

          override :value_stream
          def execute
            return forbidden unless allowed?

            success(persisted_stages.presence || build_default_stages)
          end

          private

          override :allowed?
          def allowed?
            return super unless parent.is_a?(Group)

            can?(current_user, :read_group_cycle_analytics, parent)
          end

          def persisted_stages
            scope = parent.cycle_analytics_stages
            scope = scope.by_value_stream(params[:value_stream]) if params[:value_stream]
            scope.for_list
          end

          override :value_stream
          def value_stream
            @value_stream ||= (params[:value_stream] || parent.value_streams.new(name: ::Analytics::CycleAnalytics::Stages::ListService::DEFAULT_VALUE_STREAM_NAME))
          end
        end
      end
    end
  end
end
