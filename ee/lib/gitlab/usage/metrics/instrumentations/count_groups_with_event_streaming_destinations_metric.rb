# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountGroupsWithEventStreamingDestinationsMetric < DatabaseMetric
          operation :distinct_count

          relation do
            Group.with_external_audit_event_destinations
          end
        end
      end
    end
  end
end
