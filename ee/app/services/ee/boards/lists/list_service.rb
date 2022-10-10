# frozen_string_literal: true

module EE
  module Boards
    module Lists
      module ListService
        extend ::Gitlab::Utils::Override

        private

        override :licensed_list_types
        def licensed_list_types(board)
          super + licensed_lists_for(board)
        end

        def licensed_lists_for(board)
          parent = board.resource_parent

          List::LICENSED_LIST_TYPES.each_with_object([]) do |list_type, lists|
            list_type_key = ::List.list_types[list_type]
            lists << list_type_key if parent&.feature_available?(:"board_#{list_type}_lists")
          end
        end
      end
    end
  end
end
