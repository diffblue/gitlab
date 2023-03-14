# frozen_string_literal: true

module Mutations
  module Boards
    module EpicBoards
      class EpicMoveList < ::Mutations::BaseMutation
        graphql_name 'EpicMoveList'

        authorize :admin_epic_board

        argument :board_id, ::Types::GlobalIDType[::Boards::EpicBoard],
                  required: true,
                  description: 'Global ID of the board that the epic is in.'

        argument :epic_id, ::Types::GlobalIDType[::Epic],
                  required: true,
                  description: 'ID of the epic to mutate.'

        argument :from_list_id, ::Types::GlobalIDType[::Boards::EpicList],
                  required: false,
                  description: 'ID of the board list that the epic will be moved from. Required if moving between lists.'

        argument :to_list_id, ::Types::GlobalIDType[::Boards::EpicList],
                  required: true,
                  description: 'ID of the list the epic will be in after mutation.'

        argument :move_before_id, ::Types::GlobalIDType[::Epic],
                 required: false,
                 description: 'ID of epic that should be placed before the current epic.'

        argument :move_after_id, ::Types::GlobalIDType[::Epic],
                 required: false,
                 description: 'ID of epic that should be placed after the current epic.'

        argument :position_in_list, GraphQL::Types::Int,
                 required: false,
                 description: "Position of epics within the board list. Positions start at 0. " \
                              "Use #{::Boards::Epics::MoveService::LIST_END_POSITION} to move to the end of the list."

        field :epic,
            Types::EpicType,
            null: true,
            description: 'Epic after mutation.'

        def ready?(**args)
          move_list_keys = [:from_list_id, :move_after_id, :move_before_id, :position_in_list]

          if args.slice(*move_list_keys).empty?
            camelized_keys = move_list_keys.map { |k| k.to_s.camelize(:lower) }.join(', ')

            raise Gitlab::Graphql::Errors::ArgumentError,
                  "At least one of the following parameters is required: #{camelized_keys}."
          end

          if args[:position_in_list].present?
            if args[:move_before_id].present? || args[:move_after_id].present?
              raise Gitlab::Graphql::Errors::ArgumentError,
                'positionInList is mutually exclusive with any of moveBeforeId or moveAfterId'
            end

            if args[:position_in_list] != ::Boards::Epics::MoveService::LIST_END_POSITION && args[:position_in_list] < 0
              raise Gitlab::Graphql::Errors::ArgumentError,
                    "positionInList must be >= 0 or #{::Boards::Epics::MoveService::LIST_END_POSITION}"
            end
          end

          super
        end

        def resolve(**args)
          board = authorized_find!(id: args[:board_id])
          epic = authorized_find!(id: args[:epic_id])

          move_epic(board, epic, move_list_arguments(args).merge(board_id: board.id))

          {
            epic: epic.reset,
            errors: epic.errors.full_messages
          }
        end

        private

        def move_epic(board, epic, move_params)
          service = ::Boards::Epics::MoveService.new(board.resource_parent, current_user, move_params)

          service.execute(epic)
        end

        def move_list_arguments(args)
          {
            from_list_id: args[:from_list_id]&.model_id,
            to_list_id: args[:to_list_id]&.model_id,
            move_after_id: args[:move_after_id]&.model_id,
            move_before_id: args[:move_before_id]&.model_id,
            position_in_list: args[:position_in_list]
          }
        end
      end
    end
  end
end
