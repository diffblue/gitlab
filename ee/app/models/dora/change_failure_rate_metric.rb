# frozen_string_literal: true

module Dora
  class ChangeFailureRateMetric
    include BaseMetric

    METRIC_NAME = 'change_failure_rate'

    def self.calculation_query
      'SUM(incidents_count)::float / GREATEST(SUM(deployment_frequency), 1)'
    end

    def data_queries
      # Non-production environments are ignored as we assume all Incidents happen on production
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/299096#note_550275633 for details
      return {} unless environment.production?

      queries = DeploymentFrequencyMetric.new(environment, date).data_queries

      queries[:incidents_count] = Issue.with_issue_type(:incident).select(Issue.arel_table[:id].count)
        .where(created_at: date.beginning_of_day..date.end_of_day)
        .where(project_id: environment.project_id).to_sql

      queries
    end
  end
end
