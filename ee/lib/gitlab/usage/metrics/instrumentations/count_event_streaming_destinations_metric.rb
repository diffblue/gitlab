# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountEventStreamingDestinationsMetric < DatabaseMetric
          operation :count

          relation do
            AuditEvents::ExternalAuditEventDestination
          end
        end
      end
    end
  end
end
