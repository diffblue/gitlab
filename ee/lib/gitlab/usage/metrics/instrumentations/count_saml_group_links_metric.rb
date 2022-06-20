# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountSamlGroupLinksMetric < DatabaseMetric
          operation :count

          relation do
            SamlGroupLink
          end
        end
      end
    end
  end
end
