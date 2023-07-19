# frozen_string_literal: true

module Sbom
  module Ingestion
    class OccurrenceMapCollection
      include Enumerable

      def initialize(sbom_report)
        @sbom_report = sbom_report
      end

      def each
        return to_enum(:each) unless block_given?

        sbom_report.components.sort.each do |report_component|
          yield OccurrenceMap.new(report_component, sbom_report.source)
        end
      end

      private

      attr_reader :sbom_report
    end
  end
end
