# frozen_string_literal: true

module Gitlab
  module ContributionAnalytics
    class ClickHouseDataCollector
      QUERY = <<~CH
        SELECT count(*) AS count,
          "contribution_analytics_events"."author_id" AS author_id,
          "contribution_analytics_events"."target_type" AS target_type,
          "contribution_analytics_events"."action" AS action
        FROM (
          SELECT
            id,
            argMax(author_id, contribution_analytics_events.updated_at) AS author_id,
            argMax(target_type, contribution_analytics_events.updated_at) AS target_type,
            argMax(action, contribution_analytics_events.updated_at) AS action
          FROM contribution_analytics_events
            WHERE startsWith(path, {group_path:String})
            AND "contribution_analytics_events"."created_at" >= {from:Date}
            AND "contribution_analytics_events"."created_at" <= {to:Date}
          GROUP BY id
        ) contribution_analytics_events
        GROUP BY "contribution_analytics_events"."action","contribution_analytics_events"."target_type","contribution_analytics_events"."author_id"
      CH

      attr_reader :group, :from, :to

      def initialize(group:, from:, to:)
        @group = group
        @from = from
        @to = to
      end

      def totals_by_author_target_type_action
        query = ClickHouse::Client::Query.new(raw_query: QUERY, placeholders: placeholders)
        ClickHouse::Client.select(query, :main).each_with_object({}) do |row, hash|
          hash[[row['author_id'], row['target_type'].presence, row['action']]] = row['count']
        end
      end

      private

      def group_path
        # trailing slash required to denote end of path because we use startsWith
        # to get self and descendants
        @group_path ||= "#{group.traversal_ids.join('/')}/"
      end

      def format_date(date)
        date.utc.strftime('%Y-%m-%d')
      end

      def placeholders
        {
          group_path: group_path,
          from: format_date(from),
          to: format_date(to)
        }
      end
    end
  end
end
