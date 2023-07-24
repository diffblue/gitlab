# frozen_string_literal: true

module Gitlab
  module ContributionAnalytics
    class DataCollector
      include Gitlab::Utils::StrongMemoize

      EVENT_TYPES = %i[push issues_created issues_closed merge_requests_closed merge_requests_created merge_requests_merged merge_requests_approved total_events].freeze

      attr_reader :group, :from, :to

      delegate :users, :totals, to: :data_formatter

      def initialize(group:, from: 1.week.ago.to_date, to: Date.current)
        @group = group
        @from = from.beginning_of_day
        @to = to.end_of_day
      end

      private

      def events
        @events ||= raw_counts.transform_keys do |author_id, target_type, action|
          Event.new(author_id: author_id, target_type: target_type, action: action).tap do |event|
            event.readonly!
          end
        end
      end

      def data_formatter
        @data_formatter ||= DataFormatter.new(events)
      end

      def db_data_collector
        @data_formatter ||= db_collector_klass.new(group: group, from: from, to: to)
      end

      def db_collector_klass
        return ClickHouseDataCollector if Feature.enabled?(:clickhouse_data_collection, group)

        PostgresqlDataCollector
      end
      strong_memoize_attr(:db_collector_klass)

      # Format:
      # {
      #   [user1_id, target_type, action] => count,
      #   [user2_id, target_type, action] => count
      # }
      def raw_counts
        Rails.cache.fetch(cache_key, expires_in: 1.minute) do
          db_data_collector.totals_by_author_target_type_action
        end
      end

      def cache_key
        [group, from, to]
      end
    end
  end
end
