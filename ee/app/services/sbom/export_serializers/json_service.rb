# frozen_string_literal: true

module Sbom
  module ExportSerializers
    class JsonService
      attr_reader :report, :errors

      def initialize(report)
        @report = report
        @errors = []
      end

      def execute
        json_entity = Sbom::SbomEntity.represent(report)

        schema_validator = Gitlab::Ci::Parsers::Sbom::Validators::CyclonedxSchemaValidator.new(
          json_entity.as_json.with_indifferent_access
        )

        unless schema_validator.valid?
          add_errors(schema_validator.errors)
          return
        end

        json_entity
      end

      def valid?
        errors.empty?
      end

      private

      def add_errors(errors)
        @errors |= errors
      end
    end
  end
end
