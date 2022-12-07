# frozen_string_literal: true

module EE
  module Mutations
    module WorkItems
      module Create
        extend ActiveSupport::Concern

        prepended do
          argument :iteration_widget, ::Types::WorkItems::Widgets::IterationInputType,
                   required: false,
                   description: 'Iteration widget of the work item.'
        end
      end
    end
  end
end
