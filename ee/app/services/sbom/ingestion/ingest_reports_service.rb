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
        sbom_reports.each { |report| ingest_report(report) if report.valid? }
      end

      private

      attr_reader :pipeline

      def sbom_reports
        pipeline.sbom_reports.reports
      end

      def ingest_report(sbom_report)
        IngestReportService.execute(pipeline, sbom_report)
      end
    end
  end
end
