# frozen_string_literal: true

module Iterations
  class RollOverIssuesWorker
    include ApplicationWorker

    data_consistency :always

    BATCH_SIZE = 1000

    idempotent!

    queue_namespace :iterations
    feature_category :team_planning

    def perform(iteration_ids)
      Iteration.closed.id_in(iteration_ids).each_batch(of: BATCH_SIZE) do |iterations_batch|
        iterations_batch.with_cadence.each do |iteration|
          cadence = iteration.iterations_cadence

          next unless cadence.can_roll_over?

          new_iteration = cadence.next_open_iteration(iteration.due_date)

          # proactively generate some iterations in advance if no upcoming iteration found
          # this should help prevent the case where issues roll-over is triggered but
          # cadence did not yet generate the iterations in advance
          unless new_iteration
            response = Iterations::Cadences::CreateIterationsInAdvanceService.new(automation_bot, cadence).execute
            if response.error?
              log_error(cadence, iteration, nil, response)
              next
            end
          end

          response = Iterations::RollOverIssuesService.new(automation_bot, iteration, new_iteration).execute
          log_error(cadence, iteration, new_iteration, response) if response.error?
        end
      end
    end

    private

    def log_error(cadence, from_iteration, to_iteration, response)
      logger.error(
        worker: self.class.name,
        cadence_id: cadence&.id,
        from_iteration_id: from_iteration&.id,
        to_iteration_id: to_iteration&.id,
        group_id: cadence&.group&.id,
        message: response.message
      )
    end

    def automation_bot
      @automation_bot_id ||= Users::Internal.automation_bot
    end
  end
end
