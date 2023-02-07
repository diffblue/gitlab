# frozen_string_literal: true

module Gitlab
  module LicenseScanning
    class PipelineComponents
      def initialize(pipeline:)
        @pipeline = pipeline
      end

      def fetch
        pipeline.sbom_reports.reports.flat_map do |sbom_report|
          sbom_report.components.map do |component|
            next unless component.purl

            normalized_component_name = component.purl.name
            normalized_component_name = "#{component.purl.namespace}/#{component.purl.name}" if component.purl.namespace

            Hashie::Mash.new(name: normalized_component_name, purl_type: component.purl.type,
              version: component.version)
          end.reject(&:blank?)
        end
      end

      private

      attr_reader :pipeline
    end
  end
end
