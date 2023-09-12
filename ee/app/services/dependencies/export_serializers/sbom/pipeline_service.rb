# frozen_string_literal: true

module Dependencies
  module ExportSerializers
    module Sbom
      class PipelineService
        SchemaValidationError = Class.new(StandardError)

        # Creates and execute the service.
        #
        # @param dependency_list_export [Dependencies::DependencyListExport]
        # @return [Sbom::SbomEntity] with sbom information of a pipeline.
        def self.execute(dependency_list_export)
          new(dependency_list_export).execute
        end

        def initialize(dependency_list_export)
          @dependency_list_export = dependency_list_export

          @pipeline = dependency_list_export.pipeline
          @project = pipeline.project
        end

        def execute
          entity = serializer_service.execute
          return entity if serializer_service.valid?

          raise SchemaValidationError, "Invalid CycloneDX report: #{serializer_service.errors.join(', ')}"
        end

        private

        def serializer_service
          @service ||= ::Sbom::ExportSerializers::JsonService.new(merged_report)
        end

        def merged_report
          ::Sbom::MergeReportsService.new(pipeline.sbom_reports.reports).execute
        end

        attr_reader :dependency_list_export, :scanner, :pipeline, :project
      end
    end
  end
end
