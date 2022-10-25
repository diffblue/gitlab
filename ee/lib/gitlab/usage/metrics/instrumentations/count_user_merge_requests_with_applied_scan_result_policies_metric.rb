# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountUserMergeRequestsWithAppliedScanResultPoliciesMetric < DatabaseMetric
          operation :distinct_count, column: :author_id

          relation { ::MergeRequest.with_applied_scan_result_policies }

          start { ::MergeRequest.minimum(:author_id) }
          finish { ::MergeRequest.maximum(:author_id) }
        end
      end
    end
  end
end
