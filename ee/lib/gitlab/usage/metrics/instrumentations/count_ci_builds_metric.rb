# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountCiBuildsMetric < DatabaseMetric
          relation { ::Ci::Build }
          operation :count
          metric_options do
            {
              batch_size: 1_000_000
            }
          end

          def initialize(metric_definition)
            super

            raise ArgumentError, "secure_type options attribute is required" unless secure_type.present?
            raise ArgumentError, "Attribute: #{secure_type} is not allowed" unless SECURE_PRODUCT_TYPES.include?(secure_type.to_sym)
          end

          private

          SECURE_PRODUCT_TYPES = %i[
            apifuzzer_fuzz
            apifuzzer_fuzz_dnd
            container_scanning
            coverage_fuzzing
            dast
            dependency_scanning
            license_management
            license_scanning
            sast
            secret_detection
          ].freeze

          def relation
            super.where(name: secure_type)
          end

          def secure_type
            options[:secure_type]
          end
        end
      end
    end
  end
end
