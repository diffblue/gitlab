# frozen_string_literal: true

module Resolvers
  module Geo
    class GeoNodeResolver < BaseResolver
      type Types::Geo::GeoNodeType, null: true

      argument :name, GraphQL::Types::String,
               required: false,
               description: 'The name of the Geo node. Defaults to the current Geo node name.'

      def resolve(name: GeoNode.current_node_name)
        GeoNodeFinder.new(context[:current_user], names: [name]).execute.first
      end
    end
  end
end
