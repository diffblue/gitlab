# frozen_string_literal: true

module EE
  module Gitlab
    module Usage
      module Metrics
        module Aggregates
          module Aggregate
            extend ::Gitlab::Utils::Override

            # TODO: define this missing event https://gitlab.com/gitlab-org/gitlab/-/issues/385080
            EVENTS_NOT_DEFINED_YET = %w[
              i_code_review_merge_request_widget_license_compliance_warning
            ].freeze

            private

            override :with_validate_configuration
            def with_validate_configuration(aggregation, time_frame)
              events = aggregation[:events]
              defined_events = select_defined_events(events, aggregation[:source])
              undefined_events = events - defined_events - EVENTS_NOT_DEFINED_YET

              if undefined_events.present?
                return failure(
                  ::Gitlab::Usage::Metrics::Aggregates::UndefinedEvents
                    .new("Aggregation uses events that are not defined: #{undefined_events}")
                )
              end

              super
            end

            def select_defined_events(events, source)
              # Database source metrics get validated inside the PostgresHll class:
              # https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/usage/metrics/aggregates/sources/postgres_hll.rb#L16
              return events if source != ::Gitlab::Usage::Metrics::Aggregates::REDIS_SOURCE

              events.select do |event|
                ::Gitlab::UsageDataCounters::HLLRedisCounter.known_event?(event)
              end
            end
          end
        end
      end
    end
  end
end
