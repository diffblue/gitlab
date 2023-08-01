# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class ProgressInputType < BaseInputObject
        graphql_name 'WorkItemWidgetProgressInput'

        argument :current_value,
                 GraphQL::Types::Int,
                 required: true,
                 description: 'Current progress value of the work item.'

        argument :start_value,
                  GraphQL::Types::Int,
                  required: false,
                  description: 'Start value of the work item.'

        argument :end_value,
                  GraphQL::Types::Int,
                  required: false,
                  description: 'End value of the work item.'
      end
    end
  end
end
