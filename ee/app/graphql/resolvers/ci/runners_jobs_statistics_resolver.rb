# frozen_string_literal: true

module Resolvers
  module Ci
    class RunnersJobsStatisticsResolver < BaseResolver
      include Gitlab::Utils::UsageData

      type Types::Ci::JobsStatisticsType, null: true
      description <<~MD
        Jobs statistics for jobs executed by a collection of runners. Available only to admins.
      MD

      RUNNERS_LIMIT = 5_000
      JOBS_LIMIT = 100

      def resolve(lookahead:)
        return unless Ability.allowed?(current_user, :read_jobs_statistics)

        track_usage_event(:g_runner_fleet_read_jobs_statistics, current_user.id)

        calculate_statistics(lookahead)
      end

      private

      def calculate_statistics(lookahead)
        response = {}
        if lookahead.selects?(:queued_duration)
          response[:queued_duration] = queued_durations(lookahead.selection(:queued_duration))
        end

        ::Types::Ci::JobsStatisticsType.authorized_new(response, context)
      end

      def queued_durations(selection)
        percentiles =
          ::Types::Ci::JobsDurationStatisticsType::PERCENTILES
            .filter_map { |p| percentile_disc_sql(selection, p) }
            .join(', ')

        jobs_table = ::CommitStatus.arel_table
        args = query_builder_args(jobs_table)
        jobs = ::Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder.new(**args).execute
        started_jobs_durations = jobs.select((jobs_table[:started_at] - jobs_table[:queued_at]).as('duration'))
                                     .where.not(started_at: nil) # rubocop: disable CodeReuse/ActiveRecord
                                     .where.not(runner_id: nil) # rubocop: disable CodeReuse/ActiveRecord
                                     .limit(JOBS_LIMIT)

        result = ::CommitStatus.connection.execute <<~SQL
          SELECT #{percentiles} FROM (#{started_jobs_durations.to_sql}) builds
        SQL

        convert_percentile_durations(result)
      end

      def query_builder_args(jobs_table)
        # rubocop: disable CodeReuse/ActiveRecord
        jobs_scope = ::CommitStatus.order(id: :desc)
        array_mapping_scope = ->(id_expression) { ::CommitStatus.where(jobs_table[:runner_id].eq(id_expression)) }
        finder_query = ->(id_expression) { ::CommitStatus.where(jobs_table[:id].eq(id_expression)) }
        runners_relation = object.items.reorder(id: :desc).limit(RUNNERS_LIMIT)
        # rubocop: enable CodeReuse/ActiveRecord

        {
          scope: jobs_scope,
          array_scope: runners_relation.select(:id),
          array_mapping_scope: array_mapping_scope,
          finder_query: finder_query
        }
      end

      def convert_percentile_durations(result)
        return {} unless result.count == 1

        result[0].symbolize_keys
                 .transform_values { |interval| interval ? ActiveSupport::Duration.parse(interval) : nil }
      end

      def percentile_disc_sql(selection, percentile)
        percentile_id = "p#{percentile}"

        return unless selection.selects?(percentile_id.to_sym)

        "PERCENTILE_CONT(#{percentile / 100.0}) WITHIN GROUP (ORDER BY builds.duration) AS #{percentile_id}"
      end
    end
  end
end
