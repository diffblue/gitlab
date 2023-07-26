# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        module AdvancedSearch
          class LimitedIndexingMetric < GenericMetric
            value do
              ::Gitlab::CurrentSettings.elasticsearch_limit_indexing?
            end

            available? do
              ::License.feature_available?(:elastic_search) && ::Gitlab::CurrentSettings.elasticsearch_indexing?
            end
          end
        end
      end
    end
  end
end
