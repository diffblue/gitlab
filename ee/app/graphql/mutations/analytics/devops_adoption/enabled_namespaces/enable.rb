# frozen_string_literal: true

module Mutations
  module Analytics
    module DevopsAdoption
      module EnabledNamespaces
        class Enable < BaseMutation
          graphql_name 'EnableDevopsAdoptionNamespace'
          description '**BETA** This endpoint is subject to change without notice.'

          include Mixins::CommonMethods

          argument :namespace_id, ::Types::GlobalIDType[::Namespace],
                   required: true,
                   description: 'Namespace ID.'

          argument :display_namespace_id, ::Types::GlobalIDType[::Namespace],
                   required: false,
                   description: 'Display namespace ID.'

          field :enabled_namespace,
                Types::Analytics::DevopsAdoption::EnabledNamespaceType,
                null: true,
                description: 'Enabled namespace after mutation.'

          def resolve(namespace_id:, display_namespace_id: nil, **)
            namespace = Gitlab::Graphql::Lazy.force(GitlabSchema.find_by_gid(namespace_id))
            display_namespace = Gitlab::Graphql::Lazy.force(GitlabSchema.find_by_gid(display_namespace_id))

            with_authorization_handler do
              service = ::Analytics::DevopsAdoption::EnabledNamespaces::CreateService
                .new(current_user: current_user, params: { namespace: namespace, display_namespace: display_namespace })

              response = service.execute

              resolve_enabled_namespace(response)
            end
          end
        end
      end
    end
  end
end
