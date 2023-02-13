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

        issue_params = item_filters(args[:issue_filters], board.resource_parent)

        if empty_issue_params?(issue_params) && Feature.enabled?(:board_grouped_by_epic_performance, group)
          # The service outputs an optimized query in which `ORDER` clause must appear nested inside a CTE.
          # To prevent the keyset pagination connection from appending unnecessary `ORDER` clause that
          # could make the query very slow, we are using the offset pagination connection.
          # However, this query is only more performant when there are no issue filters as it would
          # take a longer time to find matching epics.
          offset_pagination(
            ::Epics::WithIssuesFinder.new(
              accessible_epics: accessible_epics,
              accessible_issues: accessible_issues(issue_params)
            ).execute
          )
        else
          Epic.id_in(board_epic_ids(issue_params))
        end
      end

      private

      def board_epic_ids(issue_params)
        accessible_issues(issue_params).in_epics(accessible_epics).distinct_epic_ids
      end

      def accessible_issues(issue_params)
        params = issue_params.merge(all_lists: true, board_id: board.id)

        ::Boards::Issues::ListService.new(
          board.resource_parent,
          current_user,
          params
        ).execute
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

      def empty_issue_params?(issue_params)
        return true if issue_params.nil?

        issue_params.values.all? { |v| v.nil? || v.empty? }
      end
    end
  end
end
