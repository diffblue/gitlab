# frozen_string_literal: true

module Types
  module IncidentManagement
    class OncallRotationLengthInputType < BaseInputObject
      graphql_name 'OncallRotationLengthInputType'
      description 'The rotation length of the on-call rotation'

      argument :length, GraphQL::Types::Int,
                required: true,
                description: 'The rotation length of the on-call rotation.'

      argument :unit, Types::IncidentManagement::OncallRotationLengthUnitEnum,
                required: true,
                description: 'The unit of the rotation length of the on-call rotation.'
    end
  end
end
