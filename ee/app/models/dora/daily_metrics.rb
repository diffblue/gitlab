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
    METRIC_DEPLOYMENT_FREQUENCY = 'deployment_frequency'
    METRIC_LEAD_TIME_FOR_CHANGES = 'lead_time_for_changes'
    AVAILABLE_METRICS = [METRIC_DEPLOYMENT_FREQUENCY, METRIC_LEAD_TIME_FOR_CHANGES].freeze
    AVAILABLE_INTERVALS = [INTERVAL_ALL, INTERVAL_MONTHLY, INTERVAL_DAILY].freeze

    scope :for_environments, -> (environments) do
      where(environment: environments)
    end

    scope :in_range_of, -> (after, before) do
      where(date: after..before)
    end

    class << self
      def refresh!(environment, date)
        raise ArgumentError unless environment.is_a?(::Environment) && date.is_a?(Date)

        deployment_frequency = deployment_frequency(environment, date)
        lead_time_for_changes = lead_time_for_changes(environment, date)

        # This query is concurrent safe upsert with the unique index.
        connection.execute(<<~SQL)
          INSERT INTO #{table_name} (
            environment_id,
            date,
            deployment_frequency,
            lead_time_for_changes_in_seconds
          )
          VALUES (
            #{environment.id},
            #{connection.quote(date.to_s)},
            (#{deployment_frequency}),
            (#{lead_time_for_changes})
          )
          ON CONFLICT (environment_id, date)
          DO UPDATE SET
            deployment_frequency = (#{deployment_frequency}),
            lead_time_for_changes_in_seconds = (#{lead_time_for_changes})
        SQL
      end

      def aggregate_for!(metric, interval)
        data_query = data_query_for!(metric)

        case interval
        when INTERVAL_ALL
          select(data_query).take.data
        when INTERVAL_MONTHLY
          select("DATE_TRUNC('month', date)::date AS month, #{data_query}")
            .group("DATE_TRUNC('month', date)")
            .order('month ASC')
            .map { |row| { 'date' => row.month.to_s, 'value' => row.data } }
        when INTERVAL_DAILY
          select("date, #{data_query}")
            .group('date')
            .order('date ASC')
            .map { |row| { 'date' => row.date.to_s, 'value' => row.data } }
        else
          raise ArgumentError, 'Unknown interval'
        end
      end

      private

      def data_query_for!(metric)
        case metric
        when METRIC_DEPLOYMENT_FREQUENCY
          'SUM(deployment_frequency) AS data'
        when METRIC_LEAD_TIME_FOR_CHANGES
          # Median
          '(PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY lead_time_for_changes_in_seconds)) AS data'
        else
          raise ArgumentError, 'Unknown metric'
        end
      end

      # Compose a query to calculate "Deployment Frequency" of the date
      def deployment_frequency(environment, date)
        deployments = Deployment.arel_table

        deployments
          .project(deployments[:id].count)
          .where(eligible_deployments(environment, date))
          .to_sql
      end

      # Compose a query to calculate "Lead Time for Changes" of the date
      def lead_time_for_changes(environment, date)
        deployments = Deployment.arel_table
        deployment_merge_requests = DeploymentMergeRequest.arel_table
        merge_request_metrics = MergeRequest::Metrics.arel_table

        deployments
          .project(
            Arel.sql(
              'PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY EXTRACT(EPOCH FROM (deployments.finished_at - merge_request_metrics.merged_at)))'
            )
          )
          .join(deployment_merge_requests).on(
            deployment_merge_requests[:deployment_id].eq(deployments[:id])
          )
          .join(merge_request_metrics).on(
            merge_request_metrics[:merge_request_id].eq(deployment_merge_requests[:merge_request_id])
          )
          .where(eligible_deployments(environment, date))
          .to_sql
      end

      def eligible_deployments(environment, date)
        deployments = Deployment.arel_table

        [deployments[:environment_id].eq(environment.id),
         deployments[:finished_at].gteq(date.beginning_of_day),
         deployments[:finished_at].lteq(date.end_of_day),
         deployments[:status].eq(Deployment.statuses[:success])].reduce(&:and)
      end
    end
  end
end
