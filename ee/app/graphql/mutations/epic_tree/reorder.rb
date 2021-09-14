# frozen_string_literal: true

module Mutations
  module EpicTree
    class Reorder < ::Mutations::BaseMutation
      graphql_name "EpicTreeReorder"

      authorize :admin_epic

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
        moving_object_id, moving_params = coerce_input(moving_object_id, moving_params)

        result = ::Epics::TreeReorderService.new(current_user, moving_object_id, moving_params).execute
        errors = result[:status] == :error ? [result[:message]] : []

        { errors: errors }
      end

      # TODO: remove explicit coercion once compatibility layer has been removed
      # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
      def coerce_input(moving_object_id, moving_params)
        moving_object_id = ::Types::GlobalIDType[::EpicTreeSorting].coerce_isolated_input(moving_object_id)
        moving_params[:base_epic_id] = ::Types::GlobalIDType[::Epic].coerce_isolated_input(moving_params[:base_epic_id])

        if moving_params[:adjacent_reference_id]
          moving_params[:adjacent_reference_id] = ::Types::GlobalIDType[::EpicTreeSorting].coerce_isolated_input(moving_params[:adjacent_reference_id])
        end

        if moving_params[:new_parent_id]
          moving_params[:new_parent_id] = ::Types::GlobalIDType[::Epic].coerce_isolated_input(moving_params[:new_parent_id])
        end

        [moving_object_id, moving_params]
      end
    end
  end
end
