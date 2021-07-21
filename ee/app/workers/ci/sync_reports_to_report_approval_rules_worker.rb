# frozen_string_literal: true

# Worker for syncing report_type approval_rules approvals_required
module Ci
  class SyncReportsToReportApprovalRulesWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include PipelineBackgroundQueue

    urgency :high
    worker_resource_boundary :cpu

    def perform(pipeline_id)
      pipeline = Ci::Pipeline.find_by_id(pipeline_id)
      return unless pipeline

      ::Ci::SyncReportsToApprovalRulesService.new(pipeline).execute
    end
  end
end
