# frozen_string_literal: true

module Mutations
  module Geo
    module Registries
      class BulkUpdate < BaseMutation
        graphql_name 'GeoRegistriesBulkUpdate'
        description 'Mutates multiple Geo registries for a given registry class. ' \
                    'Does not mutate the registries if `geo_registries_update_mutation` feature flag is disabled.'

        extend ::Gitlab::Utils::Override

        authorize :read_geo_registry

        argument :registry_class,
          ::Types::Geo::RegistryClassEnum,
          required: true,
          description: 'Class of the Geo registries to be updated.'

        argument :action,
          ::Types::Geo::RegistriesBulkActionEnum,
          required: true,
          description: 'Action to be executed on Geo registries.'

        field :registry_class, ::Types::Geo::RegistryClassEnum, null: true, description: 'Updated Geo registry class.'

        def resolve(action:, registry_class:)
          if Feature.disabled?(:geo_registries_update_mutation)
            raise_resource_not_available_error!('`geo_registries_update_mutation` feature flag is disabled.')
          end

          raise_resource_not_available_error! unless current_user.can?(:read_all_geo, :global)

          result = ::Geo::RegistryBulkUpdateService.new(action, registry_class).execute

          { registry_class: result.payload[:registry_class], errors: result.errors }
        end

        override :read_only?
        def read_only?
          false
        end
      end
    end
  end
end
