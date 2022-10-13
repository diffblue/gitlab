# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountGroupsWithAssignedSecurityPolicyProjectMetric < DatabaseMetric
          operation :distinct_count, column: :namespace_id

          relation { ::Security::OrchestrationPolicyConfiguration }

          start { ::Security::OrchestrationPolicyConfiguration.minimum(:namespace_id) }
          finish { ::Security::OrchestrationPolicyConfiguration.maximum(:namespace_id) }
        end
      end
    end
  end
end
