# frozen_string_literal: true

module Mutations
  module Boards
    module EpicBoards
      class Destroy < ::Mutations::BaseMutation
        graphql_name 'DestroyEpicBoard'

        field :epic_board,
              Types::Boards::EpicBoardType,
              null: true,
              description: 'Epic board after mutation.'

        argument :id,
                 ::Types::GlobalIDType[::Boards::EpicBoard],
                 required: true,
                 description: 'Global ID of the board to destroy.'

        authorize :admin_epic_board

        def resolve(id:)
          board = authorized_find!(id: id)

          response = ::Boards::EpicBoards::DestroyService.new(board.resource_parent, current_user).execute(board)

          {
            epic_board: response.success? ? nil : board,
            errors: response.errors
          }
        end
      end
    end
  end
end
