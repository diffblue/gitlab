# frozen_string_literal: true

module Mutations
  module Boards
    module EpicBoards
      class Base < ::Mutations::BaseMutation
        authorize :admin_epic_board

        argument :display_colors,
          GraphQL::Types::Boolean,
          required: false,
          description: 'Whether or not display epic colors. Ignored unless `epic_color_highlight` flag is enabled.'
      end
    end
  end
end
