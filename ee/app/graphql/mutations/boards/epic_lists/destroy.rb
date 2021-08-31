# frozen_string_literal: true

module Mutations
  module Boards
    module EpicLists
      class Destroy < ::Mutations::BaseMutation
        graphql_name 'EpicBoardListDestroy'
        description 'Destroys an epic board list.'

        argument :list_id, ::Types::GlobalIDType[::Boards::EpicList],
                 required: true,
                 loads: Types::Boards::EpicListType,
                 description: 'Global ID of the epic board list to destroy.'

        field :list,
              Types::Boards::EpicListType,
              null: true,
              description: 'Epic board list. `null` if the board was destroyed successfully.'

        authorize :admin_epic_board_list

        def resolve(list:)
          raise_resource_not_available_error! unless can_admin_list?(list)

          # authorisation is handled by the service in order to return consistent responses
          # and so the service is essentially the authorisation SSOT.
          response = ::Boards::EpicLists::DestroyService.new(list.board.resource_parent, current_user).execute(list)

          list_result = response.success? ? nil : list
          mutation_response(list_result, response.errors)
        end

        def mutation_response(list_object, errors)
          {
              list: list_object,
              errors: errors
          }
        end

        private

        def can_admin_list?(list)
          Ability.allowed?(current_user, :admin_epic_board_list, list)
        end
      end
    end
  end
end
