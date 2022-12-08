# frozen_string_literal: true

module Mutations
  module EpicTree
    class Reorder < ::Mutations::BaseMutation
      graphql_name "EpicTreeReorder"

      authorize :admin_epic_relation

      argument :base_epic_id,
               ::Types::GlobalIDType[::Epic],
               required: true,
               description: 'ID of the base epic of the tree.'

      argument :moved,
               Types::EpicTree::EpicTreeNodeInputType,
               required: true,
               description: 'Parameters for updating the tree positions.'

      def resolve(args)
        moving_object_id = args[:moved][:id]
        moving_params = args[:moved].to_hash.slice(:adjacent_reference_id, :relative_position, :new_parent_id).merge(base_epic_id: args[:base_epic_id])

        result = ::Epics::TreeReorderService.new(current_user, moving_object_id, moving_params).execute
        errors = result[:status] == :error ? [result[:message]] : []

        { errors: errors }
      end
    end
  end
end
