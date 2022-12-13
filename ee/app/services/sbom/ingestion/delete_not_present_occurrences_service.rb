# frozen_string_literal: true

module Sbom
  module Ingestion
    class DeleteNotPresentOccurrencesService
      DELETE_BATCH_SIZE = 100

      def self.execute(...)
        new(...).execute
      end

      def initialize(pipeline, ingested_occurrence_ids)
        @pipeline = pipeline
        @ingested_occurrence_ids = ingested_occurrence_ids
      end

      def execute
        not_present_occurrences.each_batch(of: DELETE_BATCH_SIZE) { |occurrences, _| occurrences.delete_all }
      end

      private

      attr_reader :pipeline, :ingested_occurrence_ids

      delegate :project, to: :pipeline, private: true

      def not_present_occurrences
        project.sbom_occurrences.id_not_in(ingested_occurrence_ids)
      end
    end
  end
end
