# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountCiBuildsMetric < DatabaseMetric
          relation { ::Ci::Build }
          operation :count

          def initialize(time_frame:, options: {})
            super

            raise ArgumentError, "secure_type options attribute is required" unless secure_type.present?
            raise ArgumentError, "Attribute: #{secure_type} it not allowed" unless ::EE::Gitlab::UsageData::SECURE_PRODUCT_TYPES.key?(secure_type.to_sym)
          end

          private

          def relation
            super.where(name: secure_type) # rubocop: disable CodeReuse/ActiveRecord
          end

          def secure_type
            options[:secure_type]
          end
        end
      end
    end
  end
end
