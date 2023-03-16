# frozen_string_literal: true

module Mutations
  module Geo
    module Registries
      # For a single update, this mutation expects an `registry_id` argument.
      # A registry_class argument must be included.
      class Update < BaseMutation
        graphql_name 'GeoRegistriesUpdate'
        description 'Mutates a Geo registry. Does not mutate the registry entry if ' \
                    '`geo_registries_update_mutation` feature flag is disabled.'

        extend ::Gitlab::Utils::Override

        authorize :read_geo_registry

        argument :registry_class,
          ::Types::Geo::RegistryClassEnum,
          required: true,
          description: 'Class of the Geo registry to be updated.'

        argument :registry_id,
          Types::GlobalIDType[::Geo::BaseRegistry],
          required: true,
          description: 'ID of the Geo registry entry to be updated.'

        argument :action,
          ::Types::Geo::RegistryActionEnum,
          required: true,
          description: 'Action to be executed on a Geo registry.'

        field :registry, ::Types::Geo::RegistrableType, null: true, description: 'Updated Geo registry entry.'

        def resolve(action:, registry_id:, registry_class:)
          if Feature.disabled?(:geo_registries_update_mutation)
            raise Gitlab::Graphql::Errors::ResourceNotAvailable,
              '`geo_registries_update_mutation` feature flag is disabled.'
          end

          registry = authorized_find!(registry_id)

          result = ::Geo::RegistryUpdateService.new(action, registry_class, registry).execute

          { registry: result.payload[:registry], errors: result.errors }
        end

        override :read_only?
        def read_only?
          ::Gitlab.maintenance_mode?
        end

        private

        def find_object(id)
          GitlabSchema.find_by_gid(id)
        end
      end
    end
  end
end
