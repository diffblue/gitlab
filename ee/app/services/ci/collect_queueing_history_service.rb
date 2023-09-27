# frozen_string_literal: true

module Ci
  class CollectQueueingHistoryService
    ALLOWED_PERCENTILES = [50, 75, 90, 95, 99].freeze
    TIME_BUCKETS_LIMIT = (3.hours / 5.minutes) + 1 # +1 to add some error margin

    def initialize(current_user:, percentiles:, runner_type:, from_time:, to_time:)
      @current_user = current_user
      @percentiles = percentiles
      @runner_type = runner_type
      @from_time = from_time || 3.hours.ago.utc
      @to_time = to_time || Time.now.utc
    end

    def execute
      unless Feature.enabled?(:clickhouse_ci_analytics)
        return ServiceResponse.error(message: 'Feature clickhouse_ci_analytics not enabled')
      end

      return ServiceResponse.error(message: 'Not allowed') unless @current_user&.can?(:read_jobs_statistics)

      if (@to_time - @from_time) / 5.minutes > TIME_BUCKETS_LIMIT
        return ServiceResponse.error(message: "Maximum of #{TIME_BUCKETS_LIMIT} 5-minute intervals can be requested")
      end

      if allowed_percentiles.empty?
        return ServiceResponse.error(
          message: "At least one of #{ALLOWED_PERCENTILES.join(', ')} percentiles should be requested")
      end

      result = ClickHouse::Client.select(clickhouse_query, :main)
      ServiceResponse.success(payload: result)
    end

    private

    def clickhouse_query
      raw_query = <<~SQL.squish
        SELECT  started_at_bucket as time,
                #{percentiles_query}
        FROM    ci_finished_builds_aggregated_queueing_delay_percentiles
        WHERE   #{where_clause}
        GROUP BY started_at_bucket
        ORDER BY started_at_bucket;
      SQL

      ClickHouse::Client::Query.new(raw_query: raw_query, placeholders: placeholders)
    end

    def placeholders
      placeholders = {
        from_time: format_datetime(@from_time),
        to_time: format_datetime(@to_time)
      }

      placeholders[:runner_type] = runner_type if runner_type

      placeholders
    end

    def percentiles_query
      allowed_percentiles.map do |p|
        <<~SQL.squish
          INTERVAL quantileMerge(0.#{p})(queueing_duration_quantile) SECOND as p#{p}
        SQL
      end.join(",")
    end

    def allowed_percentiles
      ALLOWED_PERCENTILES & @percentiles
    end

    def where_clause
      where_clause = <<~SQL
        status IN ['success', 'failure'] AND
        started_at_bucket >= {from_time:DateTime('UTC', 6)} AND
        started_at_bucket <= {to_time:DateTime('UTC', 6)}
      SQL

      where_clause += " AND runner_type = {runner_type:UInt8}" if runner_type

      where_clause
    end

    def format_datetime(datetime)
      datetime&.utc&.strftime('%Y-%m-%d %H:%M:%S')
    end

    def runner_type
      ::Ci::Runner.runner_types[@runner_type]
    end
  end
end
