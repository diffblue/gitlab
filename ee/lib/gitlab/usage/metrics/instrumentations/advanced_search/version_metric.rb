# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        module AdvancedSearch
          class VersionMetric < GenericMetric
            value do
              if ::Gitlab::CurrentSettings.elasticsearch_indexing?
                ::Gitlab::Elastic::Helper.default.server_info[:version]
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
