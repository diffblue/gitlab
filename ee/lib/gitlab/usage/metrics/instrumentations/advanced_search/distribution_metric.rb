# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        module AdvancedSearch
          class DistributionMetric < GenericMetric
            value do
              if ::Gitlab::CurrentSettings.elasticsearch_indexing?
                ::Gitlab::Elastic::Helper.default.server_info[:distribution]
              else
                'NA'
              end
            end
          end
        end
      end
    end
  end
end
