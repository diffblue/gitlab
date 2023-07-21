# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountDistinctMergedMergeRequestsUsingApprovalRulesMetric < DatabaseMetric
          operation :distinct_count

          start { MergeRequest.minimum(:id) }
          finish { MergeRequest.maximum(:id) }

          relation { MergeRequest.merged.joins(:approval_rules) }

          cache_start_and_finish_as :merge_request
        end
      end
    end
  end
end
