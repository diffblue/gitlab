# frozen_string_literal: true

module EE
  module Banzai
    module Pipeline
      module GfmPipeline
        extend ActiveSupport::Concern

        class_methods do
          def metrics_filters
            [
              ::Banzai::Filter::InlineAlertMetricsFilter,
              *super
            ]
          end

          def reference_filters
            [
              ::Banzai::Filter::References::EpicReferenceFilter,
              ::Banzai::Filter::References::IterationReferenceFilter,
              ::Banzai::Filter::References::VulnerabilityReferenceFilter,
              *super
            ]
          end

          def filters
            Array(super)
          end
        end
      end
    end
  end
end
