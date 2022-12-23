# frozen_string_literal: true

module Sbom
  module Ingestion
    class IngestReportsService
      def self.execute(pipeline)
        new(pipeline).execute
      end

      def initialize(pipeline)
        @pipeline = pipeline
      end

      def execute
        ingest_reports.then { |ingested_ids| delete_not_present_occurrences(ingested_ids) }
      end

      private

      attr_reader :pipeline

      def ingest_reports
        sbom_reports.select(&:valid?).flat_map { |report| ingest_report(report) }
      end

      def sbom_reports
        pipeline.sbom_reports.reports
      end

      def ingest_report(sbom_report)
        IngestReportService.execute(pipeline, sbom_report)
      end

      def delete_not_present_occurrences(ingested_occurrence_ids)
        DeleteNotPresentOccurrencesService.execute(pipeline, ingested_occurrence_ids)
      end
    end
  end
end
