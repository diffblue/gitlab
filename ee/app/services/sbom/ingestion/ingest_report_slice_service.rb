# frozen_string_literal: true

module Sbom
  module Ingestion
    class IngestReportSliceService
      TASKS = [
        ::Sbom::Ingestion::Tasks::IngestComponents,
        ::Sbom::Ingestion::Tasks::IngestComponentVersions,
        ::Sbom::Ingestion::Tasks::IngestSources,
        ::Sbom::Ingestion::Tasks::IngestOccurrences
      ].freeze

      def self.execute(pipeline, occurrence_maps)
        new(pipeline, occurrence_maps).execute
      end

      def initialize(pipeline, occurrence_maps)
        @pipeline = pipeline
        @occurrence_maps = occurrence_maps
      end

      def execute
        ApplicationRecord.transaction do
          TASKS.each { |task| task.execute(pipeline, occurrence_maps) }
        end

        occurrence_maps.map(&:occurrence_id)
      end

      private

      attr_reader :pipeline, :occurrence_maps
    end
  end
end
