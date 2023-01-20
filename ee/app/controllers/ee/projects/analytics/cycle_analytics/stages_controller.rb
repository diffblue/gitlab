# frozen_string_literal: true
module EE
  module Projects
    module Analytics
      module CycleAnalytics
        module StagesController
          def cycle_analytics_configuration(stages)
            return super if requests_default_value_stream?

            stage_presenters = stages.map { |s| ::Analytics::CycleAnalytics::StagePresenter.new(s) }

            ::Analytics::CycleAnalytics::ConfigurationEntity.new(stages: stage_presenters)
          end

          def only_default_value_stream_is_allowed!
            super unless ::Gitlab::Analytics::CycleAnalytics.licensed?(namespace)
          end

          def authorize_stage
            super if !::Gitlab::Analytics::CycleAnalytics.licensed?(namespace) && requests_default_value_stream?
          end
        end
      end
    end
  end
end
