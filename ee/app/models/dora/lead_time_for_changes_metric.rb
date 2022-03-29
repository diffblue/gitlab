# frozen_string_literal: true

module Dora
  class LeadTimeForChangesMetric
    include BaseMetric

    METRIC_NAME = 'lead_time_for_changes'

    def self.calculation_query
      # Median
      '(PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY lead_time_for_changes_in_seconds))'
    end

    def data_queries
      deployments = Deployment.arel_table
      deployment_merge_requests = DeploymentMergeRequest.arel_table
      merge_request_metrics = MergeRequest::Metrics.arel_table

      query = deployments
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
        .where(eligible_deployments)

      {
        lead_time_for_changes_in_seconds: query.to_sql
      }
    end
  end
end
