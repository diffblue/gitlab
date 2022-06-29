# frozen_string_literal: true

class ProjectImportScheduleWorker
  include ApplicationWorker

  data_consistency :delayed, feature_flag: :delayed_project_import_schedule_worker

  idempotent!
  deduplicate :until_executing, ttl: 5.minutes

  feature_category :source_code_management
  sidekiq_options retry: 1
  loggable_arguments 1 # For the job waiter key
  log_bulk_perform_async!

  def perform(project_id)
    ::Gitlab::Mirror.untrack_scheduling(project_id)

    return if Gitlab::Database.read_only?

    project = Project.with_route.with_import_state.with_namespace.find_by_id(project_id)

    with_context(project: project) do
      unless project&.import_state
        log_extra_metadata_on_done(:mirroring_skipped, "No import state found for #{project_id}")
        next
      end

      project.import_state.schedule
    end
  end
end
