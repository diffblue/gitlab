# frozen_string_literal: true

module EE
  module Analytics
    module CycleAnalytics
      module Stages
        module ListService
          extend ::Gitlab::Utils::Override

          def execute
            return super unless value_stream.custom?
            return forbidden unless allowed? && ::Gitlab::Analytics::CycleAnalytics.licensed?(parent)

            success(persisted_stages)
          end

          private

          def persisted_stages
            parent.cycle_analytics_stages.by_value_stream(params[:value_stream]).for_list
          end

          def allowed?
            case parent
            when Group
              can?(current_user, :read_group_cycle_analytics, parent)
            else
              super
            end
          end
        end
      end
    end
  end
end
