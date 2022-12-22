# frozen_string_literal: true

module EE
  module Gitlab
    module Usage
      module Metrics
        module Aggregates
          module Aggregate
            extend ::Gitlab::Utils::Override

            private

            override :with_validate_configuration
            def with_validate_configuration(aggregation, time_frame)
              events = aggregation[:events]
              defined_events = select_defined_events(events, aggregation[:source])
              undefined_events = events - defined_events

              if undefined_events.present?
                return failure(
                  ::Gitlab::Usage::Metrics::Aggregates::UndefinedEvents
                    .new("Aggregation uses events that are not defined: #{undefined_events}")
                )
              end

              super
            end
          end
        end
      end
    end
  end
end
