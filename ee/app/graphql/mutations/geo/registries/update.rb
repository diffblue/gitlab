# frozen_string_literal: true

module Mutations
  module Geo
    module Registries
      class Update < BaseMutation
        graphql_name 'GeoRegistriesUpdate'
        description 'Mutates a Geo registry. Does not mutate the registry entry if ' \
                    '`geo_registries_update_mutation` feature flag is disabled.'

        extend ::Gitlab::Utils::Override

        authorize :read_geo_registry

        argument :registry_class,
          ::Types::Geo::RegistryClassEnum,
          required: false,
          default_value: nil,
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

        # TODO: `registry_class` argument is unused in this mutation
        # and it is `required: false`, expecting to be removed entirely.
        # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/424563
        def resolve(action:, registry_id:, registry_class:)  # rubocop:disable Lint/UnusedMethodArgument
          if Feature.disabled?(:geo_registries_update_mutation)
            raise_resource_not_available_error!('`geo_registries_update_mutation` feature flag is disabled.')
          end

          registry = authorized_find!(registry_id)

          result = ::Geo::RegistryUpdateService.new(action, registry).execute

          { registry: result.payload[:registry], errors: result.errors }
        end

        override :read_only?
        def read_only?
          false
        end

        private

        def find_object(id)
          GitlabSchema.find_by_gid(id)
        end
      end
    end
  end
end
