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
            Hashie::Mash.new(name: component.name, purl_type: component.purl.type, version: component.version)
          end
        end
      end

      private

      attr_reader :pipeline
    end
  end
end
