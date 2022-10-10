# frozen_string_literal: true

module Boards
  module EpicLists
    class ListService < ::Boards::Lists::ListService
      private

      def visible_lists(board)
        [].tap do |visible|
          visible << ::Boards::EpicList.list_types[:backlog] unless board.hide_backlog_list?
          visible << ::Boards::EpicList.list_types[:closed] unless board.hide_closed_list?
        end
      end
    end
  end
end
