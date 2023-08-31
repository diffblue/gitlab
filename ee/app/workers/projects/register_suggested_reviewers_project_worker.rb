# frozen_string_literal: true

module Projects
  class RegisterSuggestedReviewersProjectWorker
    include ApplicationWorker

    data_consistency :always
    feature_category :code_review_workflow
    urgency :low
    deduplicate :until_executed

    sidekiq_options retry: 3

    idempotent!

    # ::Projects::RegisterSuggestedReviewersProjectService makes an external RPC request
    worker_has_external_dependencies!

    def perform(project_id, user_id)
      project = Project.find_by_id(project_id)
      return unless project && project.suggested_reviewers_available? && project.suggested_reviewers_enabled

      user = User.find_by_id(user_id)
      return unless user

      response = ::Projects::RegisterSuggestedReviewersProjectService.new(project: project, current_user: user).execute
      if response.error?
        handle_error(response, project_id)
      else
        handle_success(response)
      end
    end

    private

    def handle_error(response, project_id)
      case response.reason
      when :client_request_failed
        response.track_and_raise_exception(project_id: project_id)
      when :project_already_registered
        # ignore
        response
      else
        response.track_exception(project_id: project_id)
      end
    end

    def handle_success(response)
      log_extra_metadata_on_done(:project_id, response.payload[:project_id])
      log_extra_metadata_on_done(:registered_at, response.payload[:registered_at])
    end
  end
end
