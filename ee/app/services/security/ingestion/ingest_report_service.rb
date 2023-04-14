# frozen_string_literal: true

module Security
  module Ingestion
    # This class splits the ingestion of the vulnerabilities
    # of a security scan into multiple batches.
    #
    # Returns the ingested vulnerability IDs for each batch.
    class IngestReportService
      BATCH_SIZE = 50
      INGESTION_ERROR = {
        type: 'IngestionError',
        message: 'Ingestion failed for some vulnerabilities'
      }.freeze

      def self.execute(security_scan)
        new(security_scan).execute
      end

      def initialize(security_scan)
        @security_scan = security_scan
        @errored = false
      end

      def execute
        finding_map_collection.each_slice(BATCH_SIZE)
          .flat_map { |slice| ingest_slice(slice) }
      end

      private

      attr_reader :security_scan
      attr_accessor :errored

      delegate :pipeline, :scanners, to: :security_scan, private: true

      def finding_map_collection
        @finding_map_collection ||= FindingMapCollection.new(security_scan)
      end

      def ingest_slice(slice)
        IngestReportSliceService.execute(pipeline, slice)
      rescue StandardError => error
        process_error(error)
      end

      def process_error(error)
        Gitlab::ErrorTracking.track_exception(error)
        set_ingestion_error!

        # we are explicitly returning an empty array for the caller service.
        # Otherwise, the return value will be the result of the `set_ingestion_error!` method.
        []
      end

      def set_ingestion_error!
        return if errored

        self.errored = true
        security_scan.add_processing_error!(INGESTION_ERROR)
      end
    end
  end
end
