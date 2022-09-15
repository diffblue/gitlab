# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        # Usage example
        #
        # In metric YAML definition:
        #
        # instrumentation_class: RedisMetric
        # options:
        #   event: pushes
        #   prefix: source_code
        #
        class RedisMetric < BaseMetric
          include Gitlab::UsageDataCounters::RedisCounter

          USAGE_PREFIX = "USAGE_"

          def initialize(time_frame:, options: {})
            super

            raise ArgumentError, "'event' option is required" unless metric_event.present?
            raise ArgumentError, "'prefix' option is required" unless prefix.present?
          end

          def metric_event
            options[:event]
          end

          def prefix
            options[:prefix]
          end

          def include_usage_prefix?
            options.fetch(:include_usage_prefix, true)
          end

          def value
            redis_usage_data do
              total_count(redis_key)
            end
          end

          def suggested_name
            Gitlab::Usage::Metrics::NameSuggestion.for(:redis)
          end

          private

          def usage_prefix
            include_usage_prefix? ? USAGE_PREFIX : ""
          end

          def redis_key
            "#{usage_prefix}#{prefix}_#{metric_event}".upcase
          end
        end
      end
    end
  end
end
