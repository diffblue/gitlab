# frozen_string_literal: true

module Vulnerabilities
  module HistoricalStatistics
    class UpdateService
      UPSERT_SQL = <<~SQL
        INSERT INTO vulnerability_historical_statistics
          (project_id, total, info, unknown, low, medium, high, critical, letter_grade, date, created_at, updated_at)
          (%{stats_sql})
        ON CONFLICT (project_id, date)
        DO UPDATE SET
          total = EXCLUDED.total,
          info = EXCLUDED.info,
          unknown = EXCLUDED.unknown,
          low = EXCLUDED.low,
          medium = EXCLUDED.medium,
          high = EXCLUDED.high,
          critical = EXCLUDED.critical,
          letter_grade = EXCLUDED.letter_grade,
          updated_at = EXCLUDED.updated_at
      SQL

      STATS_SQL = <<~SQL
        SELECT
          project_id,
          total,
          info,
          unknown,
          low,
          medium,
          high,
          critical,
          letter_grade,
          updated_at AS date,
          now() AS created_at,
          now() AS updated_at
        FROM vulnerability_statistics
        WHERE project_id = %{project_id}
      SQL

      def self.update_for(project)
        new(project).execute
      end

      def initialize(project)
        @project = project
      end

      def execute
        return unless update_statistic?

        ApplicationRecord.connection.execute(upsert_sql)
      end

      private

      attr_reader :project

      delegate :vulnerability_statistic, to: :project

      def update_statistic?
        keep_statistics_always_consistent? && vulnerability_statistic.present?
      end

      def keep_statistics_always_consistent?
        Feature.enabled?(:keep_historical_vulnerability_statistics_always_consistent, project)
      end

      def upsert_sql
        UPSERT_SQL % { stats_sql: stats_sql }
      end

      def stats_sql
        STATS_SQL % { project_id: project.id }
      end
    end
  end
end
