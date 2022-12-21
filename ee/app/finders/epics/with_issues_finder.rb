# frozen_string_literal: true

# Returns all epics that match
module Epics
  class WithIssuesFinder
    def initialize(accessible_epics:, accessible_issues:)
      @accessible_epics = accessible_epics
      @accessible_issues = accessible_issues
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def execute
      return Epic.none if accessible_epics == Epic.none

      Epic
        .select(Arel.star)
        .with(epics_cte.to_arel)
        .from(epics_cte.table.name)
        .where('EXISTS (?)', issues_joined_with_epics)
        .order(id: :desc)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    attr_reader :accessible_epics, :accessible_issues

    # rubocop: disable CodeReuse/ActiveRecord
    def epics_cte
      @epics_cte ||= Gitlab::SQL::CTE.new(:sorted_epics, accessible_epics)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def issues_joined_with_epics
      accessible_issues
        .without_order
        .joins(:epic_issue)
        .where(EpicIssue.arel_table[:epic_id].eq(epics_cte.table[:id]))
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
