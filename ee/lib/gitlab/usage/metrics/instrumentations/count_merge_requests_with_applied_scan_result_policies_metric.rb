# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountMergeRequestsWithAppliedScanResultPoliciesMetric < DatabaseMetric
          operation :distinct_count, column: :merge_request_id

          relation { ::ApprovalMergeRequestRule.scan_finding }

          start { ::ApprovalMergeRequestRule.minimum(:merge_request_id) }
          finish { ::ApprovalMergeRequestRule.maximum(:merge_request_id) }
        end
      end
    end
  end
end
