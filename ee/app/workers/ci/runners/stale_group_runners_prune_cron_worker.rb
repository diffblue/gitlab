# frozen_string_literal: true

module Ci
  module Runners
    class StaleGroupRunnersPruneCronWorker
      # rubocop:disable Scalability/CronWorkerContext
      # This worker does not provide context as a performance optimization: it joins the stale runners from
      # batches of groups that opted in for the pruning

      include ApplicationWorker
      include CronjobQueue

      data_consistency :always
      feature_category :runner_fleet
      urgency :low

      idempotent!

      def perform
        namespace_ids = NamespaceCiCdSetting.allowing_stale_runner_pruning.select(:namespace_id)

        ::Ci::Runners::StaleGroupRunnersPruneService.new.perform(namespace_ids)
      end
    end
  end
end
