# frozen_string_literal: true

class IterationsUpdateStatusWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  BATCH_SIZE = 1000

  idempotent!

  queue_namespace :cronjob
  feature_category :team_planning

  def perform
    set_current_iterations
    set_closed_iterations
  end

  private

  def set_current_iterations
    Iteration.upcoming.start_date_passed.each_batch(of: BATCH_SIZE) do |iterations|
      iterations.update_all(state_enum: ::Iteration::STATE_ENUM_MAP[:current], updated_at: Time.current)
    end
  end

  def set_closed_iterations
    Iteration.opened.due_date_passed.each_batch(of: BATCH_SIZE) do |iterations|
      closed_iteration_ids = iterations.pluck_primary_key
      iterations.update_all(state_enum: ::Iteration::STATE_ENUM_MAP[:closed], updated_at: Time.current)

      Iterations::RollOverIssuesWorker.perform_async(closed_iteration_ids)
    end
  end
end
