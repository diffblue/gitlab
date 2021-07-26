# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class LicenseMdFiveMetric < ::Gitlab::Usage::Metrics::Instrumentations::GenericMetric
          value do
            ::License.current.md5
          end
        end
      end
    end
  end
end
