# frozen_string_literal: true

module Types
  module IncidentManagement
    # rubocop: disable Graphql/AuthorizeTypes
    class OncallRotationActivePeriodInputType < BaseInputObject
      graphql_name 'OncallRotationActivePeriodInputType'
      description 'Active period time range for on-call rotation'

      argument :start_time, GraphQL::Types::String,
                required: true,
                description: 'The start of the rotation active period in 24 hour format, for example "18:30".'

      argument :end_time, GraphQL::Types::String,
                required: true,
                description: 'The end of the rotation active period in 24 hour format, for example "18:30".'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
