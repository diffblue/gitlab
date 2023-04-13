# frozen_string_literal: true

module Dora
  class DeploymentFrequencyMetric
    include BaseMetric

    METRIC_NAME = 'deployment_frequency'

    # The SQL query returns deployments count which will be post-processed
    # in the AggregateMetricsService class. Reasoning: The frequency calculation
    # must take into account the given date range (count / number of days).
    def self.calculation_query
      'SUM(deployment_frequency)'
    end

    def data_queries
      deployments = Deployment.arel_table

      {
        deployment_frequency: deployments.project(deployments[:id].count).where(eligible_deployments).to_sql
      }
    end
  end
end
