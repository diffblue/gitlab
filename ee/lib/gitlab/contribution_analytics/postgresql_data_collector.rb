# frozen_string_literal: true

module Gitlab
  module ContributionAnalytics
    class PostgresqlDataCollector
      attr_reader :group, :from, :to

      def initialize(group:, from:, to:)
        @group = group
        @from = from
        @to = to
      end

      def totals_by_author_target_type_action
        base_query.totals_by_author_target_type_action
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord
      def base_query
        cte = Gitlab::SQL::CTE.new(:project_ids,
          ::Route
            .where(source_type: 'Project')
            .where(::Route.arel_table[:path].matches("#{::Route.sanitize_sql_like(group.full_path)}/%", nil, true))
            .select('source_id AS id'))
        cte_condition = 'project_id IN (SELECT id FROM project_ids)'

        events_from_date = ::Event
          .where(cte_condition)
          .where(Event.arel_table[:created_at].gteq(from))
          .where(Event.arel_table[:created_at].lteq(to))

        ::Event.with(cte.to_arel).from_union(
          [
            events_from_date.where(action: :pushed, target_type: nil),
            events_from_date.where(
              action: [:created, :closed, :merged, :approved],
              target_type: [::MergeRequest.name, ::Issue.name])
          ], remove_duplicates: false)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
