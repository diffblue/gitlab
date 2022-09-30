# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountUsersCreatingCiBuildsMetric < DatabaseMetric
          relation { ::Ci::Build }

          operation :distinct_count, column: :user_id
          cache_start_and_finish_as :count_users_creating_ci_builds

          start { ::User.minimum(:id) }
          finish { ::User.maximum(:id) }

          def initialize(metric_definition)
            super

            raise ArgumentError, "secure_type options attribute is required" unless secure_type.present?
            raise ArgumentError, "Attribute: #{secure_type} is not allowed" unless ::EE::Gitlab::UsageData::SECURE_PRODUCT_TYPES.key?(secure_type.to_sym)
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
