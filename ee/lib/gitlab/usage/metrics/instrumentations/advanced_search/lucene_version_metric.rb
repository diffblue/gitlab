# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        module AdvancedSearch
          class LuceneVersionMetric < GenericMetric
            value do
              if ::Gitlab::CurrentSettings.elasticsearch_indexing?
                ::Gitlab::Elastic::Helper.default.server_info[:lucene_version]
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
