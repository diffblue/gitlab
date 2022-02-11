# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        module Validators
          class SchemaValidator
            SUPPORTED_VERSIONS = {
              container_scanning: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0],
              coverage_fuzzing: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0],
              dast: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0],
              dependency_scanning: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0],
              sast: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0],
              secret_detection: %w[14.0.0 14.0.1 14.0.2 14.0.3 14.0.4 14.0.5 14.0.6 14.1.0]
            }.freeze

            DEPRECATED_VERSIONS = {
              container_scanning: %w[],
              coverage_fuzzing: %w[],
              dast: %w[],
              dependency_scanning: %w[],
              sast: %w[],
              secret_detection: %w[]
            }.freeze

            class Schema
              def root_path
                File.join(__dir__, 'schemas')
              end

              def initialize(report_type)
                @report_type = report_type.to_sym
              end

              delegate :validate, to: :schemer

              private

              attr_reader :report_type

              def schemer
                JSONSchemer.schema(pathname)
              end

              def pathname
                Pathname.new(schema_path)
              end

              def schema_path
                File.join(root_path, file_name)
              end

              def file_name
                report_type == :api_fuzzing ? "dast-report-format.json" : "#{report_type.to_s.dasherize}-report-format.json"
              end
            end

            def initialize(report_type, report_data)
              @report_type = report_type
              @report_data = report_data
            end

            def valid?
              errors.empty?
            end

            def errors
              @errors ||= schema.validate(report_data).map { |error| JSONSchemer::Errors.pretty(error) }
            end

            private

            attr_reader :report_type, :report_data

            def schema
              Schema.new(report_type)
            end
          end
        end
      end
    end
  end
end

Gitlab::Ci::Parsers::Security::Validators::SchemaValidator::Schema.prepend_mod_with("Gitlab::Ci::Parsers::Security::Validators::SchemaValidator::Schema")
