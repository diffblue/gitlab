# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class ProgressInputType < BaseInputObject
        graphql_name 'WorkItemWidgetProgressInput'

        argument :progress, GraphQL::Types::Int,
                 required: true,
                 description: 'Progress of the work item.'
      end
    end
  end
end
