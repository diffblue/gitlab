# frozen_string_literal: true

module Sbom
  module Ingestion
    class OccurrenceMap
      attr_reader :report_component, :report_source
      attr_accessor :component_id, :component_version_id, :source_id, :occurrence_id

      def initialize(report_component, report_source)
        @report_component = report_component
        @report_source = report_source
      end

      def to_h
        {
          component_id: component_id,
          component_version_id: component_version_id,
          component_type: report_component.component_type,
          name: component_name,
          purl_type: purl_type,
          source_id: source_id,
          source_type: report_source&.source_type,
          source: report_source&.data,
          version: version
        }
      end

      def version_present?
        version.present?
      end

      delegate :version, to: :report_component, private: true

      private

      def purl_type
        report_component.purl&.type
      end

      def component_name
        ::Sbom::PackageUrl::Normalizer.new(type: purl_type, text: report_component.name).normalize_name
      end
    end
  end
end
