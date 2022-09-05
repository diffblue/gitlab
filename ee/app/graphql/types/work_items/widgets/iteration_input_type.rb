# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class IterationInputType < BaseInputObject
        graphql_name 'WorkItemWidgetIterationInput'

        argument :iteration_id,
                 ::Types::GlobalIDType[::Iteration],
                 required: false,
                 loads: Types::IterationType,
                 description: 'Iteration to assign to the work item.'
      end
    end
  end
end
