# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        module AdvancedSearch
          class BuildTypeMetric < GenericMetric
            value do
              if ::Gitlab::CurrentSettings.elasticsearch_indexing?
                ::Gitlab::Elastic::Helper.default.server_info[:build_type]
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
