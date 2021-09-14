# frozen_string_literal: true

# Disabling this cop as the auth check is happening in ProfileScheduleType.
# ProfileCadenceType is a dependent entity on ProfileScheduleType and does not exist without it.
# rubocop:disable Graphql/AuthorizeTypes

module Types
  module Dast
    class ProfileCadenceType < BaseObject
      graphql_name 'DastProfileCadence'
      description 'Represents DAST Profile Cadence.'

      field :unit, ::Types::Dast::ProfileCadenceUnitEnum,
            null: true,
            description: 'Unit for the duration of DAST profile cadence.'

      field :duration, GraphQL::Types::Int,
            null: true,
            description: 'Duration of the DAST profile cadence.'
    end
  end
end
