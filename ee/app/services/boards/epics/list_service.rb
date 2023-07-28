# frozen_string_literal: true

module Boards
  module Epics
    class ListService < Boards::BaseItemsListService
      private

      def finder
        EpicsFinder.new(current_user, filter_params.merge(group_id: parent.id))
      end

      def filter(collection)
        items = filter_by_from_id(collection)
        items = filter_by_position_presence(items)

        super(items)
      end

      def metadata_fields(required_fields)
        fields = super

        if required_fields&.include?(:total_weight)
          fields[:total_weight] = Arel.sql('COALESCE(SUM(total_opened_issue_weight+total_closed_issue_weight), 0)')
        end

        fields[:epics_count] = Arel.sql('COUNT(distinct epics.id)') if required_fields&.include?(:epics_count)
        fields
      end

      def filter_by_from_id(items)
        return items unless params[:from_id].present?

        items.from_id(params[:from_id])
      end

      def filter_by_position_presence(items)
        return items unless exclude_positioned?

        items.join_board_position(board.id).without_board_position(board.id)
      end

      def exclude_positioned?
        params[:exclude_positioned].present?
      end

      def board
        @board ||= params[:board].presence || parent.epic_boards.find(params[:board_id])
      end

      def order(items)
        items = items.join_board_position(board.id) if needs_board_position?

        return items.order_closed_at_desc if list&.closed?

        items.order_relative_position_on_board(board.id)
      end

      def needs_board_position?
        # we need to join board's relative position only for unclosed lists
        # or if we are filling missing positions in the list
        exclude_positioned? || !list&.closed?
      end

      def item_model
        ::Epic
      end
    end
  end
end
