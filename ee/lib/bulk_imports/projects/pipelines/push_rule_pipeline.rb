# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class PushRulePipeline
        include NdjsonPipeline

        relation_name 'push_rule'

        extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation
      end
    end
  end
end
