# frozen_string_literal: true

module Ci
  module Runners
    class StaleGroupRunnersPruneCronWorker
      # rubocop:disable Scalability/CronWorkerContext
      # This worker does not provide context as a performance optimization: it joins the stale runners from
      # batches of groups that opted in for the pruning

      include ApplicationWorker
      include CronjobQueue

      data_consistency :sticky
      feature_category :runner_fleet
      urgency :low

      idempotent!

      def perform
        namespace_ids = NamespaceCiCdSetting.allowing_stale_runner_pruning.select(:namespace_id)

        result = ::Ci::Runners::StaleGroupRunnersPruneService.new.execute(namespace_ids)
        log_extra_metadata_on_done(:status, result.status)
        log_hash_metadata_on_done(result.payload)
      end
    end
  end
end
