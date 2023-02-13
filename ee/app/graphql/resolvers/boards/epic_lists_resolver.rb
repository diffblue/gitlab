# frozen_string_literal: true

module Resolvers
  module Boards
    class EpicListsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource
      include LooksAhead
      include ::BoardItemFilterable

      type Types::Boards::EpicListType.connection_type, null: true

      argument :id, ::Types::GlobalIDType[::Boards::EpicList],
               required: false,
               description: 'Find an epic board list by ID.'

      argument :epic_filters, Types::Boards::BoardEpicInputType,
               required: false,
               description: 'Filters applied when getting epic metadata in the epic board list.'

      alias_method :epic_board, :object

      def resolve_with_lookahead(id: nil, epic_filters: {})
        authorize!

        lists = board_lists(id)
        context.scoped_set!(:epic_filters, item_filters(epic_filters, epic_board.resource_parent))

        if load_preferences?(lookahead)
          ::Boards::EpicList.preload_preferences_for_user(lists, current_user)
        end

        offset_pagination(apply_lookahead(lists))
      end

      private

      def board_lists(id)
        service = ::Boards::EpicLists::ListService.new(
          epic_board.resource_parent,
          current_user,
          list_id: id&.model_id
        )

        service.execute(epic_board, create_default_lists: false)
      end

      def load_preferences?(lookahead)
        lookahead&.selection(:edges)&.selection(:node)&.selects?(:collapsed) ||
            lookahead&.selection(:nodes)&.selects?(:collapsed)
      end

      def authorize!
        Ability.allowed?(context[:current_user], :read_epic_board_list, epic_board.group) || raise_resource_not_available_error!
      end

      def preloads
        {
          label: [:label]
        }
      end
    end
  end
end
