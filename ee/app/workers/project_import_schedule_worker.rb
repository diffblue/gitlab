# frozen_string_literal: true

class ProjectImportScheduleWorker
  ImportStateNotFound = Class.new(StandardError)

  include ApplicationWorker
  # At the moment, this inclusion is to enable job tracking ability. In the
  # future, the capacity management should be moved to this worker instead of
  # UpdateAllMirrorsWorker
  include LimitedCapacity::Worker

  data_consistency :always
  prepend WaitableWorker

  idempotent!
  deduplicate :until_executing, ttl: 5.minutes

  feature_category :source_code_management
  sidekiq_options retry: false
  loggable_arguments 1 # For the job waiter key
  log_bulk_perform_async!

  # UpdateAllMirrorsWorker depends on the queue size of this worker:
  # https://gitlab.com/gitlab-org/gitlab/-/issues/340630
  tags :needs_own_queue

  def perform(project_id)
    job_tracker.register(jid, capacity) if job_tracking?

    return if Gitlab::Database.read_only?

    project = Project.with_route.with_import_state.with_namespace.find_by_id(project_id)
    raise ImportStateNotFound unless project&.import_state

    with_context(project: project) do
      project.import_state.schedule
    end
  ensure
    job_tracker.remove(jid) if job_tracking?
  end

  private

  def capacity
    Gitlab::Mirror.available_capacity
  end

  def job_tracking?
    Feature.enabled?(:project_import_schedule_worker_job_tracker, default_enabled: :yaml)
  end
end
