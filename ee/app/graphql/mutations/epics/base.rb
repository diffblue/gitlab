# frozen_string_literal: true

module Mutations
  module Epics
    class Base < ::Mutations::BaseMutation
      include Mutations::ResolvesIssuable

      argument :iid, GraphQL::Types::ID,
               required: true,
               description: "IID of the epic to mutate."

      argument :group_path, GraphQL::Types::ID,
               required: true,
               description: 'Group the epic to mutate belongs to.'

      field :epic,
            Types::EpicType,
            null: true,
            description: 'Epic after mutation.'

      private

      def find_object(group_path:, iid:)
        resolve_issuable(type: :epic, parent_path: group_path, iid: iid)
      end
    end
  end
end
