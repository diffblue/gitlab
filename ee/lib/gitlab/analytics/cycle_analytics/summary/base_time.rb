# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module Summary
        class BaseTime
          def initialize(stage:, current_user:, options:)
            @stage = stage
            @current_user = current_user
            @options = options

            assign_event_identifiers
          end

          def value
            @value ||= Gitlab::CycleAnalytics::Summary::Value::PrettyNumeric.new(data_collector.median.days&.round(1))
          end

          def unit
            n_('day', 'days', value)
          end

          def start_event_identifier
            raise NotImplementedError, "Expected #{self.name} to implement start_event_identifier"
          end

          def end_event_identifier
            raise NotImplementedError, "Expected #{self.name} to implement end_event_identifier"
          end

          def links
            []
          end

          private

          def assign_event_identifiers
            @stage.start_event_identifier = start_event_identifier
            @stage.end_event_identifier = end_event_identifier
          end

          def data_collector
            Gitlab::Analytics::CycleAnalytics::DataCollector.new(
              stage: @stage,
              params: {
                from: @options[:from],
                to: @options[:to] || DateTime.now,
                project_ids: @options[:projects],
                end_event_filter: @options[:end_event_filter],
                current_user: @current_user
              }.merge(@options.slice(*::Gitlab::Analytics::CycleAnalytics::RequestParams::FINDER_PARAM_NAMES))
            )
          end
        end
      end
    end
  end
end
