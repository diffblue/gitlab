# frozen_string_literal: true

module Gitlab
  module Metrics
    module GlobalSearchIndexingSlis
      class << self
        # The following targets are the 99.95th percentile of indexing
        # gathered on 20-10-2022
        # Code/Wikis
        # from https://log.gprd.gitlab.net/goto/8cbc1920-3432-11ed-8656-f5f2137823ba (internal only)
        #
        # Other
        # (TODO) https://log.gprd.gitlab.net/goto/a6f274b0-3432-11ed-8656-f5f2137823ba (internal only)
        CODE_INDEXING_TARGET_S    = 120.0
        CONTENT_INDEXING_TARGET_S = 4.878

        def initialize_slis!
          Gitlab::Metrics::Sli::Apdex.initialize_sli(:global_search_indexing, possible_labels)
        end

        def record_apdex(elapsed:, document_type:)
          Gitlab::Metrics::Sli::Apdex[:global_search_indexing].increment(
            labels: labels(document_type: document_type),
            success: elapsed < duration_target(document_type)
          )
        end

        private

        def duration_target(indexing_type)
          indexing_type == 'Code' ? CODE_INDEXING_TARGET_S : CONTENT_INDEXING_TARGET_S
        end

        def document_types
          indexable_models + %w[Code Wiki]
        end

        def indexable_models
          # This will gather the names of all classes that include Elastic::ApplicationVersionedSearch
          # Classes that include this module will be tracked and updated by ProcessBookkeepingService
          ::ApplicationRecord.descendants.filter_map do |model|
            model.to_s if model.include?(::Elastic::ApplicationVersionedSearch)
          end
        end

        def possible_labels
          document_types.map do |document_type|
            {
              document_type: document_type
            }
          end
        end

        def labels(document_type:)
          {
            document_type: document_type
          }
        end
      end
    end
  end
end
