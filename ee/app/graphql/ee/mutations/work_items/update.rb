# frozen_string_literal: true

module EE
  module Mutations
    module WorkItems
      module Update
        extend ActiveSupport::Concern

        prepended do
          argument :iteration_widget, ::Types::WorkItems::Widgets::IterationInputType,
                   required: false,
                   description: 'Input for iteration widget.'

          argument :weight_widget, ::Types::WorkItems::Widgets::WeightInputType,
                   required: false,
                   description: 'Input for weight widget.'

          argument :progress_widget, ::Types::WorkItems::Widgets::ProgressInputType,
                   required: false,
                   description: 'Input for progress widget.'

          argument :status_widget, ::Types::WorkItems::Widgets::StatusInputType,
                   required: false,
                   description: 'Input for status widget.'

          argument :health_status_widget, ::Types::WorkItems::Widgets::HealthStatusInputType,
                   required: false,
                   description: 'Input for health status widget.'
        end
      end
    end
  end
end
