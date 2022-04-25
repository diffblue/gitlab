# frozen_string_literal: true

module Resolvers
  module Boards
    class BoardListEpicsResolver < BaseResolver
      type Types::EpicType.connection_type, null: true

      alias_method :list, :object

      argument :filters, Types::Boards::BoardEpicInputType,
         required: false,
         description: 'Filters applied when selecting epics in the board list.'

      def resolve(filters: {}, **args)
        filter_params = { board: list.epic_board, list: list }.merge(filters)

        service = ::Boards::Epics::ListService.new(
          list.epic_board.group,
          context[:current_user],
          filter_params
        )

        offset_pagination(service.execute)
      end
    end
  end
end
