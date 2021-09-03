# frozen_string_literal: true

module Mutations
  module Namespaces
    class Base < ::Mutations::BaseMutation
      argument :id, ::Types::GlobalIDType[::Namespace],
               required: true,
               description: 'Global ID of the namespace to mutate.'

      field :namespace,
            Types::NamespaceType,
            null: true,
            description: 'Namespace after mutation.'

      private

      def find_object(id:)
        # TODO: remove this line when the compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id = Types::GlobalIDType[::Namespace].coerce_isolated_input(id)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
