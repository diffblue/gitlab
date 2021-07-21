# frozen_string_literal: true

class ProjectImportScheduleWorker
  ImportStateNotFound = Class.new(StandardError)

  include ApplicationWorker

  data_consistency :always
  prepend WaitableWorker

  idempotent!
  feature_category :source_code_management
  sidekiq_options retry: false
  loggable_arguments 1 # For the job waiter key

  def perform(project_id)
    return if Gitlab::Database.read_only?

    project = Project.with_route.with_import_state.with_namespace.find_by_id(project_id)
    raise ImportStateNotFound unless project&.import_state

    with_context(project: project) do
      project.import_state.schedule
    end
  end
end
