# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class ZuoraSubscriptionIdMetric < ::Gitlab::Usage::Metrics::Instrumentations::GenericMetric
          value do
            ::License.current.subscription_id
          end
        end
      end
    end
  end
end
