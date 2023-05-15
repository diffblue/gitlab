# frozen_string_literal: true

module Dora
  # DevOps Research and Assessment (DORA) key metrics. Deployment Frequency,
  # Lead Time for Changes, Change Failure Rate and Time to Restore Service
  # are tracked as daily summary.
  # Reference: https://cloud.google.com/blog/products/devops-sre/using-the-four-keys-to-measure-your-devops-performance
  class DailyMetrics < ApplicationRecord
    belongs_to :environment

    self.table_name = 'dora_daily_metrics'

    INTERVAL_ALL = 'all'
    INTERVAL_MONTHLY = 'monthly'
    INTERVAL_DAILY = 'daily'
    AVAILABLE_INTERVALS = [INTERVAL_ALL, INTERVAL_MONTHLY, INTERVAL_DAILY].freeze
    AVAILABLE_METRICS = BaseMetric.all_metric_classes.map { |klass| klass::METRIC_NAME }.freeze

    scope :for_environments, -> (environments) do
      where(environment: environments)
    end

    scope :in_range_of, -> (after, before) do
      where(date: after..before)
    end

    scope :for_project_production, -> (project) do
      environment = project.environments.production.limit(1)

      for_environments(environment)
    end

    class << self
      def aggregate_for!(metrics, interval)
        select_query_part = metrics.map do |metric|
          "#{BaseMetric.for(metric).calculation_query} as metric_#{metric}"
        end.join(', ')

        case interval
        when INTERVAL_ALL
          row = select(select_query_part).take
          [transform_aggregated_row(row.attributes.merge('interval_date' => nil), metrics)]
        when INTERVAL_MONTHLY
          select("DATE_TRUNC('month', date)::date AS interval_date, #{select_query_part}")
            .group("DATE_TRUNC('month', date)")
            .order('interval_date ASC')
            .map { |row| transform_aggregated_row(row, metrics) }
        when INTERVAL_DAILY
          select("date AS interval_date, #{select_query_part}")
            .group('date')
            .order('interval_date ASC')
            .map { |row| transform_aggregated_row(row, metrics) }
        else
          raise ArgumentError, 'Unknown interval'
        end
      end

      def refresh!(environment, date)
        raise ArgumentError unless environment.is_a?(::Environment) && date.is_a?(Date)

        queries_to_refresh = BaseMetric.all_metric_classes.inject({}) do |queries, klass|
          queries.merge(klass.new(environment, date).data_queries)
        end

        return unless queries_to_refresh.present?

        # This query is concurrent safe upsert with the unique index.
        connection.execute(<<~SQL)
          INSERT INTO #{table_name} (
            environment_id,
            date,
            #{queries_to_refresh.keys.join(', ')}
          )
          VALUES (
            #{environment.id},
            #{connection.quote(date.to_s)},
            #{queries_to_refresh.map { |_column, query| "(#{query})" }.join(', ')}
          )
          ON CONFLICT (environment_id, date)
          DO UPDATE SET
            #{queries_to_refresh.map { |column, query| "#{column} = (#{query})" }.join(', ')}
        SQL

        Dora::PerformanceScore.refresh!(environment.project, date) if environment.production?
      end

      private

      def transform_aggregated_row(row, metrics)
        result = { 'date' => row['interval_date']&.to_s }
        metrics.each do |key|
          result[key.to_s] = row["metric_#{key}"]
        end

        result
      end
    end
  end
end
