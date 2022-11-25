# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountMergeRequestsWithAppliedScanResultPoliciesMetric < DatabaseMetric
          BATCH_SIZE = 50_000

          operation :distinct_count, column: :merge_request_id
          metric_options do
            {
              batch_size: BATCH_SIZE
            }
          end

          relation { ::ApprovalMergeRequestRule.scan_finding }

          start { ::ApprovalMergeRequestRule.minimum(:merge_request_id) }
          finish { ::ApprovalMergeRequestRule.maximum(:merge_request_id) }
        end
      end
    end
  end
end
