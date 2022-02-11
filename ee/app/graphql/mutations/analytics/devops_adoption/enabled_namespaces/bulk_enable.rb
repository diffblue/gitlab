# frozen_string_literal: true

module Mutations
  module Analytics
    module DevopsAdoption
      module EnabledNamespaces
        class BulkEnable < BaseMutation
          graphql_name 'BulkEnableDevopsAdoptionNamespaces'
          description '**BETA** This endpoint is subject to change without notice.'

          include Mixins::CommonMethods

          argument :namespace_ids, [::Types::GlobalIDType[::Namespace]],
                   required: true,
                   description: 'List of Namespace IDs.'

          argument :display_namespace_id, ::Types::GlobalIDType[::Namespace],
                   required: false,
                   description: 'Display namespace ID.'

          field :enabled_namespaces,
                [::Types::Analytics::DevopsAdoption::EnabledNamespaceType],
                null: true,
                description: 'Enabled namespaces after mutation.'

          def resolve(namespace_ids:, display_namespace_id: nil, **)
            namespaces = GlobalID::Locator.locate_many(namespace_ids)
            display_namespace = Gitlab::Graphql::Lazy.force(GitlabSchema.find_by_gid(display_namespace_id))

            with_authorization_handler do
              service = ::Analytics::DevopsAdoption::EnabledNamespaces::BulkFindOrCreateService
                .new(current_user: current_user, params: { namespaces: namespaces, display_namespace: display_namespace })

              enabled_namespaces = service.execute.payload.fetch(:enabled_namespaces)

              {
                enabled_namespaces: enabled_namespaces.select(&:persisted?),
                errors: enabled_namespaces.sum { |ns| errors_on_object(ns) }
              }
            end
          end
        end
      end
    end
  end
end
