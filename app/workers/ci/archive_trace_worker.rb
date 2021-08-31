# frozen_string_literal: true

module Ci
  class ArchiveTraceWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include PipelineBackgroundQueue

    # rubocop: disable CodeReuse/ActiveRecord
    def perform(job_id)
      ci_build_scope.find_by(id: job_id).try do |job|
        Ci::ArchiveTraceService.new.execute(job, worker_name: self.class.name)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def ci_build_scope
      if Feature.enabled?(:ci_enable_live_trace)
        Ci::Build.with_live_trace
      else
        Ci::Build.without_archived_trace
      end
    end
  end
end
