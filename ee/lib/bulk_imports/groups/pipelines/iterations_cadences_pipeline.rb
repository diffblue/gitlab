# frozen_string_literal: true

module BulkImports
  module Groups
    module Pipelines
      class IterationsCadencesPipeline
        include BulkImports::NdjsonPipeline

        relation_name 'iterations_cadences'

        extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation
      end
    end
  end
end
