# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class WeightInputType < BaseInputObject
        graphql_name 'WorkItemWidgetWeightInput'

        argument :weight, GraphQL::Types::Int,
                 required: :nullable,
                 description: 'Weight of the work item.'
      end
    end
  end
end
