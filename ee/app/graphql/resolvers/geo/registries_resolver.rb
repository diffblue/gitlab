# frozen_string_literal: true

module Resolvers
  module Geo
    module RegistriesResolver
      extend ActiveSupport::Concern

      included do
        def self.replicator_class
          Gitlab::Geo::Replicator.for_class_name(self.name)
        end

        delegate :registry_class, :registry_finder_class, to: :replicator_class

        type replicator_class.graphql_registry_type, null: true

        argument :ids,
                 [GraphQL::Types::ID],
                 required: false,
                 description: 'Filters registries by their ID.'

        def resolve(ids: nil)
          return registry_class.none unless geo_node_is_current?

          registry_finder_class.new(
            context[:current_user],
            ids: registry_ids(ids)
          ).execute
        end

        private

        def replicator_class
          self.class.replicator_class
        end

        def registry_ids(ids)
          ids&.map { |id| GlobalID.parse(id)&.model_id }&.compact
        end

        # We can't query other nodes' tracking databases
        def geo_node_is_current?
          GeoNode.current?(geo_node)
        end

        def geo_node
          object
        end
      end
    end
  end
end
