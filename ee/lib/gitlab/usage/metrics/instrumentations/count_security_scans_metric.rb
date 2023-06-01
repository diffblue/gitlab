# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountSecurityScansMetric < DatabaseMetric
          operation :count, column: :build_id

          start { ::Security::Scan.minimum(:build_id) }
          finish { ::Security::Scan.maximum(:build_id) }
          metric_options do
            {
              batch_size: 1_000_000
            }
          end

          relation { ::Security::Scan }

          def initialize(metric_definition)
            super

            return if scan_types.include?(scan_type)

            raise ArgumentError, "scan_type must be present and one of: #{scan_types.join(', ')}"
          end

          private

          def relation
            super.by_scan_types(scan_type)
          end

          def scan_type
            options[:scan_type]
          end

          def scan_types
            ::Security::Scan.scan_types.except('cluster_image_scanning').keys
          end
        end
      end
    end
  end
end
