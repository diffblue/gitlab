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

      if Feature.enabled?(:dora_configuration, environment.project)
        merge_requests = MergeRequest.arel_table
        dora_configurations = Dora::Configuration.arel_table

        query = query
          .join(merge_requests).on(
            merge_requests[:id].eq(deployment_merge_requests[:merge_request_id])
          )
          .outer_join(dora_configurations).on(
            dora_configurations[:project_id].eq(deployments[:project_id])
          )
          .where(eligible_merge_requests)
      end

      {
        lead_time_for_changes_in_seconds: query.to_sql
      }
    end

    private

    def eligible_merge_requests
      merge_requests = MergeRequest.arel_table
      dora_configurations = Dora::Configuration.arel_table

      [
        dora_configurations[:branches_for_lead_time_for_changes].eq(nil),
        dora_configurations[:branches_for_lead_time_for_changes].eq([]),
        merge_requests[:target_branch].eq(
          Arel::Nodes::NamedFunction.new("ANY", [dora_configurations[:branches_for_lead_time_for_changes]])
        )
      ].reduce(&:or)
    end
  end
end
