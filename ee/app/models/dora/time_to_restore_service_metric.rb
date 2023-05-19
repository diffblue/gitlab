# frozen_string_literal: true

module Dora
  class TimeToRestoreServiceMetric
    include BaseMetric

    METRIC_NAME = 'time_to_restore_service'

    def self.calculation_query
      # Median
      '(PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY time_to_restore_service_in_seconds))'
    end

    def data_queries
      # Non-production environments are ignored as we assume all Incidents happen on production
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/299096#note_550275633 for details
      #
      return {} unless environment.production?

      query = Issue.with_issue_type(:incident).closed.select(
        Arel.sql(
          'PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY EXTRACT(EPOCH FROM (issues.closed_at - issues.created_at)))'
        ))
        .where(closed_at: date.beginning_of_day..date.end_of_day)
        .where(project_id: environment.project_id)

      {
        time_to_restore_service_in_seconds: query.to_sql
      }
    end
  end
end
