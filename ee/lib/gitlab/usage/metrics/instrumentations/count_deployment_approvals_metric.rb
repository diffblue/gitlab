# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountDeploymentApprovalsMetric < DatabaseMetric
          operation :count

          relation { ::Deployments::Approval }
        end
      end
    end
  end
end
