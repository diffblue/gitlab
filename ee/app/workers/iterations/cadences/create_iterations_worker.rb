# frozen_string_literal: true

module Iterations
  module Cadences
    class CreateIterationsWorker
      include ApplicationWorker

      data_consistency :always

      idempotent!
      deduplicate :until_executed, including_scheduled: true

      queue_namespace :cronjob
      feature_category :issue_tracking

      def perform(cadence_id)
        cadence = ::Iterations::Cadence.find_by_id(cadence_id)
        return unless cadence && cadence.group.iteration_cadences_feature_flag_enabled? # keep this behind FF for now

        response = Iterations::Cadences::CreateIterationsInAdvanceService.new(automation_bot, cadence).execute
        log_error(cadence, response) if response.error?
      end

      private

      def log_error(cadence, response)
        logger.error(
          worker: self.class.name,
          cadence_id: cadence&.id,
          group_id: cadence&.group&.id,
          message: response.message
        )
      end

      def automation_bot
        @automation_bot_id ||= User.automation_bot
      end
    end
  end
end
