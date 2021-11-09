# frozen_string_literal: true

module Gitlab
  module Database
    # The purpose of this class is to implement a various query analyzers based on `pg_query`
    # And process them all via `Gitlab::Database::QueryAnalyzers::*`
    class QueryAnalyzer
      include ::Singleton

      ANALYZERS = [].freeze

      Parsed = Struct.new(
        :sql, :connection, :pg
      )

      def hook!
        @subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |event|
          # In some cases analyzer code might trigger another SQL call
          # to avoid stack too deep this detects recursive call of subscriber
          with_ignored_recursive_calls do
            process_sql(event.payload[:sql], event.payload[:connection])
          end
        end
      end

      private

      def process_sql(sql, connection)
        analyzers = enabled_analyzers(connection)
        return unless analyzers.any?

        parsed = parse(sql, connection)
        return unless parsed

        analyzers.each do |analyzer|
          analyzer.analyze(parsed)
        rescue => e # rubocop:disable Style/RescueStandardError
          # We catch all standard errors to prevent validation errors to introduce fatal errors in production
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
        end
      end

      def enabled_analyzers(connection)
        ANALYZERS.select do |analyzer|
          analyzer.enabled?(connection)
        rescue StandardError => e # rubocop:disable Style/RescueStandardError
          # We catch all standard errors to prevent validation errors to introduce fatal errors in production
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
        end
      end

      def parse(sql, connection)
        parsed = PgQuery.parse(sql)
        return unless parsed

        normalized = PgQuery.normalize(sql)
        Parsed.new(normalized, connection, parsed)
      rescue PgQuery::ParseError => e
        # Ignore PgQuery parse errors (due to depth limit or other reasons)
        Gitlab::ErrorTracking.track_exception(e)

        nil
      end

      def with_ignored_recursive_calls
        return if Thread.current[:query_analyzer_recursive]

        begin
          Thread.current[:query_analyzer_recursive] = true
          yield
        ensure
          Thread.current[:query_analyzer_recursive] = nil
        end
      end
    end
  end
end
