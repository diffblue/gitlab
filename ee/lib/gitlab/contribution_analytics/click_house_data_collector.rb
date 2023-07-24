# frozen_string_literal: true

module Gitlab
  module ContributionAnalytics
    class ClickHouseDataCollector
      # Use AR module for preventing SQL injection
      include ActiveRecord::ConnectionAdapters::Quoting

      attr_reader :group, :from, :to

      def initialize(group:, from:, to:)
        @group = group
        @from = from
        @to = to
      end

      def totals_by_author_target_type_action
        clickhouse_query = <<~CH
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
              WHERE startsWith(path, #{group_path})
              AND "contribution_analytics_events"."created_at" >= #{format_date(from)}
              AND "contribution_analytics_events"."created_at" <= #{format_date(to)}
            GROUP BY id
          ) contribution_analytics_events
          GROUP BY "contribution_analytics_events"."action","contribution_analytics_events"."target_type","contribution_analytics_events"."author_id"
        CH

        ClickHouse::Client.select(clickhouse_query, :main).each_with_object({}) do |row, hash|
          hash[[row['author_id'], row['target_type'], row['action']]] = row['count']
        end
      end

      private

      def group_path
        # trailing slash required to denote end of path because we use startsWith
        # to get self and descendants
        @group_path ||= quote("#{group.traversal_ids.join('/')}/")
      end

      def format_date(date)
        quote(date.utc.strftime('%Y-%m-%d'))
      end
    end
  end
end
