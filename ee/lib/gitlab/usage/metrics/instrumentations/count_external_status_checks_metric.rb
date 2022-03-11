# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountExternalStatusChecksMetric < DatabaseMetric
          operation :count

          relation do
            ::MergeRequests::ExternalStatusCheck
          end
        end
      end
    end
  end
end
