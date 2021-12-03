# frozen_string_literal: true

module EE
  module Boards
    module Lists
      module ListService
        extend ::Gitlab::Utils::Override

        override :execute
        def execute(board, create_default_lists: true)
          list_types = unavailable_list_types_for(board)

          super.without_types(list_types)
        end

        private

        def unavailable_list_types_for(board)
          list_types = super
          list_types += unlicensed_lists_for(board)

          list_types.uniq
        end

        def unlicensed_lists_for(board)
          parent = board.resource_parent

          List::LICENSED_LIST_TYPES.each_with_object([]) do |list_type, lists|
            list_type_key = ::List.list_types[list_type]
            lists << list_type_key unless parent&.feature_available?(:"board_#{list_type}_lists")
          end
        end
      end
    end
  end
end
