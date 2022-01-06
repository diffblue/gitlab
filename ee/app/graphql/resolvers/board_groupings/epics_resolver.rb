# frozen_string_literal: true

module Resolvers
  module BoardGroupings
    class EpicsResolver < BaseResolver
      include ::BoardItemFilterable

      alias_method :board, :object

      argument :issue_filters, Types::Boards::BoardIssueInputType,
               required: false,
               description: 'Filters applied when selecting issues on the board.'

      type Types::Boards::BoardEpicType, null: true

      def resolve(**args)
        return Epic.none unless board.present?
        return Epic.none unless group.present?

        context.scoped_set!(:board, board)

        Epic.id_in(board_epic_ids(args[:issue_filters]))
      end

      private

      def board_epic_ids(issue_params)
        params = item_filters(issue_params).merge(all_lists: true, board_id: board.id)

        list_service = ::Boards::Issues::ListService.new(
          board.resource_parent,
          current_user,
          params
        )

        list_service.execute.in_epics(accessible_epics).distinct_epic_ids
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def accessible_epics
        EpicsFinder.new(
          context[:current_user],
          group_id: group.id,
          state: :opened,
          include_ancestor_groups: true,
          include_descendant_groups: board.group_board?
        ).execute.reorder(nil) # Not having order here increases performance, epics will be ordering on parent query anyway.
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def group
        board.project_board? ? board.project.group : board.group
      end
    end
  end
end
