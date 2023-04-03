# frozen_string_literal: true

module Projects
  class DeregisterSuggestedReviewersProjectService < BaseProjectService
    def execute
      unless project_deregistration_available?
        return ServiceResponse.error(
          message: 'Suggested Reviewers deregistration is unavailable',
          reason: :feature_unavailable
        )
      end

      result = ::Gitlab::AppliedMl::SuggestedReviewers::Client.new.deregister_project(
        project_id: project.id
      )

      ServiceResponse.success(payload: result)
    rescue Gitlab::AppliedMl::Errors::ProjectNotFound
      ServiceResponse.error(message: 'Project is not found', reason: :project_not_found)
    rescue Gitlab::AppliedMl::Errors::ResourceNotAvailable
      ServiceResponse.error(message: 'Failed to deregister project', reason: :client_request_failed)
    end

    private

    def project_deregistration_available?
      project.suggested_reviewers_available? && !project.suggested_reviewers_enabled
    end
  end
end
