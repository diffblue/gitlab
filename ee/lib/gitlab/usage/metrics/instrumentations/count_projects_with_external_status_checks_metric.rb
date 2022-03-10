# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountProjectsWithExternalStatusChecksMetric < DatabaseMetric
          operation :distinct_count, column: 'project_id'

          relation do
            ::MergeRequests::ExternalStatusCheck
          end
        end
      end
    end
  end
end
