# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class GenericMetric < BaseMetric
          # Usage example
          #
          # class UuidMetric < GenericMetric
          #   value do
          #     Gitlab::CurrentSettings.uuid
          #   end
          # end
          FALLBACK = -1

          class << self
            attr_reader :metric_operation
            @metric_operation = :alt

            def fallback(custom_fallback)
              @metric_fallback = custom_fallback
            end

            def value(&block)
              @metric_value = block
            end

            attr_reader :metric_value, :metric_fallback
          end

          def value
            alt_usage_data(fallback: fallback) do
              self.class.metric_value.call
            end
          end

          def suggested_name
            Gitlab::Usage::Metrics::NameSuggestion.for(
              self.class.metric_operation
            )
          end

          def fallback
            self.class.metric_fallback || FALLBACK
          end
        end
      end
    end
  end
end
