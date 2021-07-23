# frozen_string_literal: true

module Types
  module Iterations
    class CadenceType < BaseObject
      graphql_name 'IterationCadence'
      description 'Represents an iteration cadence'

      authorize :read_iteration_cadence

      field :id, ::Types::GlobalIDType[::Iterations::Cadence], null: false,
        description: 'Global ID of the iteration cadence.'

      field :title, GraphQL::Types::String, null: false,
        description: 'Title of the iteration cadence.'

      field :duration_in_weeks, GraphQL::Types::Int, null: true,
        description: 'Duration in weeks of the iterations within this cadence.'

      field :iterations_in_advance, GraphQL::Types::Int, null: true,
        description: 'Future iterations to be created when iteration cadence is set to automatic.'

      field :start_date, Types::TimeType, null: true,
        description: 'Timestamp of the iteration cadence start date.'

      field :automatic, GraphQL::Types::Boolean, null: true,
        description: 'Whether the iteration cadence should automatically generate future iterations.'

      field :active, GraphQL::Types::Boolean, null: true,
        description: 'Whether the iteration cadence is active.'

      field :roll_over, GraphQL::Types::Boolean, null: false,
        description: 'Whether the iteration cadence should roll over issues to the next iteration or not.'

      field :description, GraphQL::Types::String, null: true,
        description: 'Description of the iteration cadence. Maximum length is 5000 characters.'
    end
  end
end
