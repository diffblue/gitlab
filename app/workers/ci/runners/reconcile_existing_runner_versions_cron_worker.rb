# frozen_string_literal: true

module Ci
  module Runners
    class ReconcileExistingRunnerVersionsCronWorker
      include ApplicationWorker

      # This worker does not schedule other workers that require context.
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

      data_consistency :sticky
      feature_category :runner_fleet
      urgency :low

      idempotent!
      deduplicate :until_executing

      def perform(cronjob_scheduled = true)
        if cronjob_scheduled
          # Introduce some randomness across the day so that instances don't all hit the GitLab Releases API
          # around the same time of day
          period = rand(0..ActiveSupport::Duration::SECONDS_PER_DAY)
          self.class.perform_in(period, false)

          Sidekiq.logger.info(
            class: self.class.name,
            message: "rescheduled job for #{period.seconds.from_now}")

          return
        end

        result = ::Ci::Runners::ReconcileExistingRunnerVersionsService.new.execute
        result.each { |key, value| log_extra_metadata_on_done(key, value) }
      end
    end
  end
end
