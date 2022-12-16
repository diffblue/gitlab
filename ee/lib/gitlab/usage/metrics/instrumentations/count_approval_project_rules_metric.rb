# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountApprovalProjectRulesMetric < DatabaseMetric
          operation :count

          relation { ApprovalProjectRule }
        end
      end
    end
  end
end
