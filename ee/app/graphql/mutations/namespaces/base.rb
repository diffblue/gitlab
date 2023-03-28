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
    end
  end
end
