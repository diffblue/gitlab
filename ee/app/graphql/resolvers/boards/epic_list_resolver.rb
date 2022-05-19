# frozen_string_literal: true

module Resolvers
  module Boards
    class EpicListResolver < BaseResolver.single
      include Gitlab::Graphql::Authorize::AuthorizeResource
      include ::BoardItemFilterable

      type Types::Boards::EpicListType, null: true

      argument :id, ::Types::GlobalIDType[::Boards::EpicList],
        required: true,
        loads: Types::Boards::EpicListType,
        as: :list,
        description: 'Global ID of the list.'

      argument :epic_filters, ::Types::Boards::BoardEpicInputType,
        required: false,
        description: 'Filters applied when getting epic metadata in the epic board list.'

      authorize :read_epic_board_list

      def resolve(list:, epic_filters: {})
        authorize! list

        context.scoped_set!(:epic_filters, item_filters(epic_filters))

        list
      end
    end
  end
end
