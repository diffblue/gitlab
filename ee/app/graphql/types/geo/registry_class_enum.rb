# frozen_string_literal: true

module Types
  module Geo
    class RegistryClassEnum < BaseEnum
      graphql_name 'GeoRegistryClass'
      description 'Geo registry class'

      # Example format:
      #  value "MERGE_REQUEST_DIFF_REGISTRY",
      #  value: "Geo::MergeRequestDiffRegistry",
      #  description: "Geo::MergeRequestDiffRegistry registry class"
      ::Geo::Secondary::RegistryConsistencyWorker::REGISTRY_CLASSES.each do |registry_class|
        next unless registry_class.graphql_mutable?

        # Disabling RuboCop: `graphql_enum_key` adheres to the uppercase rule of Graphql/EnumValues.
        value registry_class.graphql_enum_key, # rubocop:disable Graphql/EnumValues
          value: registry_class.to_s,
          description: "#{registry_class} registry class"
      end
    end
  end
end
