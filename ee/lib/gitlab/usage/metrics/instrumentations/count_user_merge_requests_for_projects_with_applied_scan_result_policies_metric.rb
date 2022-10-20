# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountUserMergeRequestsForProjectsWithAppliedScanResultPoliciesMetric < DatabaseMetric
          operation :distinct_count, column: :author_id

          relation { ::MergeRequest.for_projects_with_security_policy_project }

          start { ::MergeRequest.minimum(:author_id) }
          finish { ::MergeRequest.maximum(:author_id) }
        end
      end
    end
  end
end
