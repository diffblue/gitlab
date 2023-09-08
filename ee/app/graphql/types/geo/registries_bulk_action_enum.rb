# frozen_string_literal: true

module Types
  module Geo
    class RegistriesBulkActionEnum < BaseEnum
      graphql_name 'GeoRegistriesBulkAction'
      description 'Action to trigger on multiple Geo registries'

      value 'REVERIFY_ALL', value: :reverify_all, description: 'Reverify multiple registries.'
      value 'RESYNC_ALL', value: :resync_all, description: 'Resync multiple registries.'
    end
  end
end
