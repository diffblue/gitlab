# frozen_string_literal: true

module Mutations
  module Boards
    class UpdateEpicUserPreferences < ::Mutations::BaseMutation
      graphql_name 'UpdateBoardEpicUserPreferences'

      argument :board_id,
               ::Types::GlobalIDType[::Board],
               required: true,
               description: 'The board global ID.'

      argument :epic_id,
               ::Types::GlobalIDType[::Epic],
               required: true,
               description: 'ID of an epic to set preferences for.'

      argument :collapsed,
               GraphQL::Types::Boolean,
               required: true,
               description: 'Whether the epic should be collapsed in the board.'

      field :epic_user_preferences,
            Types::Boards::EpicUserPreferencesType,
            null: true,
            description: 'User preferences for the epic in the board after mutation.'

      authorize :read_issue_board

      def resolve(board_id:, epic_id:, **args)
        board = authorized_find!(id: board_id)
        raise_resource_not_available_error! unless epic = find_epic(epic_id)

        result = ::Boards::EpicUserPreferences::UpdateService.new(
          current_user, board, epic, { collapsed: args[:collapsed] }).execute

        {
          epic_user_preferences: result[:epic_user_preferences],
          errors: result[:status] == :error ? [result[:message]] : []
        }
      end

      private

      def find_epic(epic_id)
        epic = Epic.find(epic_id.model_id)
        return unless Ability.allowed?(current_user, :read_epic, epic)

        epic
      rescue ActiveRecord::RecordNotFound
        nil
      end

      def find_object(id:)
        GitlabSchema.object_from_id(id, expected_type: ::Board)
      end
    end
  end
end
