# frozen_string_literal: true

module Types
  module Geo
    class RegistryActionEnum < BaseEnum
      graphql_name 'GeoRegistryAction'
      description 'Action to trigger on one or more Geo registries'

      value 'REVERIFY', value: :reverify, description: 'Reverify a registry.'
      value 'RESYNC', value: :resync, description: 'Resync a registry.'
    end
  end
end
