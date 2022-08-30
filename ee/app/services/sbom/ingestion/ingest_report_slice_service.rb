# frozen_string_literal: true

module Sbom
  module Ingestion
    class IngestReportSliceService
      TASKS = %i[
        IngestComponents
        IngestComponentVersions
        IngestSources
        IngestOccurrences
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
          TASKS.each { |task| execute_task(task) }
        end
      end

      private

      attr_reader :pipeline, :occurrence_maps

      def execute_task(task)
        Tasks.const_get(task, false).execute(pipeline, occurrence_maps)
      end
    end
  end
end
