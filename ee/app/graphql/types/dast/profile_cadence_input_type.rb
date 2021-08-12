# frozen_string_literal: true

module Types
  module Dast
    class ProfileCadenceInputType < BaseInputObject
      graphql_name 'DastProfileCadenceInput'
      description 'Represents DAST Profile Cadence.'

      argument :unit, ::Types::Dast::ProfileCadenceUnitEnum,
            required: false,
            description: 'Unit for the duration of DAST Profile Cadence.'

      argument :duration, GraphQL::Types::Int,
            required: false,
            description: 'Duration of the DAST Profile Cadence.'
    end
  end
end
