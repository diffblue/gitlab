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

        sorted_components.each do |report_component|
          yield OccurrenceMap.new(report_component, sbom_report.source)
        end
      end

      private

      attr_reader :sbom_report

      def sorted_components
        sbom_report.components.sort_by { |component| sort_index(component) }
      end

      def sort_index(component)
        [
          component.name,
          purl_type_int(component),
          component_type_int(component),
          component&.version.to_s
        ]
      end

      def component_type_int(component)
        ::Enums::Sbom::COMPONENT_TYPES.fetch(component.component_type.to_sym, 0)
      end

      def purl_type_int(component)
        ::Enums::Sbom::PURL_TYPES.fetch(component.purl&.type&.to_sym, 0)
      end
    end
  end
end
