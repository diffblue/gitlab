# frozen_string_literal: true

class AdjournedProjectDeletionWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include ExceptionBacktrace

  feature_category :authentication_and_authorization

  def perform(project_id)
    project = Project.find(project_id)
    user = project.deleting_user

    return unless user

    ::Projects::DestroyService.new(project, user).async_execute
  rescue ActiveRecord::RecordNotFound => error
    logger.error("Failed to delete project (#{project_id}): #{error.message}")
  end
end
