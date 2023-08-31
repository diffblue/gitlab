# frozen_string_literal: true

module Projects
  class DeregisterSuggestedReviewersProjectWorker
    include ApplicationWorker

    data_consistency :delayed
    feature_category :code_review_workflow
    urgency :low
    deduplicate :until_executed

    sidekiq_options retry: 3

    idempotent!

    # ::Projects::DeregisterSuggestedReviewersProjectService makes an external RPC request
    worker_has_external_dependencies!

    def perform(project_id, user_id)
      project = Project.find_by_id(project_id)
      return unless project && project.suggested_reviewers_available? && !project.suggested_reviewers_enabled

      user = User.find_by_id(user_id)
      return unless user

      response = ::Projects::DeregisterSuggestedReviewersProjectService
        .new(project: project, current_user: user)
        .execute

      handle_result(response, project_id)
    end

    private

    def handle_result(response, project_id)
      return if response.error? && response.reason != :client_request_failed
      return response.track_and_raise_exception(project_id: project_id) if response.error?

      log_hash_metadata_on_done(
        project_id: response.payload[:project_id],
        deregistered_at: response.payload[:deregistered_at]
      )
    end
  end
end
