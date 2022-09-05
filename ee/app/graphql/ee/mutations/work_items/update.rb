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
        end
      end
    end
  end
end
