# frozen_string_literal: true

module Mutations
  module Boards
    module EpicBoards
      class Update < ::Mutations::BaseMutation
        graphql_name 'EpicBoardUpdate'

        include Mutations::Boards::CommonMutationArguments
        prepend Mutations::Boards::ScopedBoardMutation

        authorize :admin_epic_board

        argument :id,
                 ::Types::GlobalIDType[::Boards::EpicBoard],
                 required: true,
                 description: 'Epic board global ID.'

        field :epic_board,
              Types::Boards::EpicBoardType,
              null: true,
              description: 'Updated epic board.'

        def resolve(**args)
          board = authorized_find!(id: args[:id])

          ::Boards::EpicBoards::UpdateService.new(board.resource_parent, current_user, args).execute(board)

          {
            epic_board: board.reset,
            errors: errors_on_object(board)
          }
        end

        private

        def find_object(id:)
          GitlabSchema.find_by_gid(id)
        end
      end
    end
  end
end
