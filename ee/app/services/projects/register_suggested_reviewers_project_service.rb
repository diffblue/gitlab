# frozen_string_literal: true

module Projects
  class RegisterSuggestedReviewersProjectService < BaseProjectService
    def execute
      unless project_registration_available?
        return ServiceResponse.error(
          message: 'Suggested Reviewers feature is unavailable',
          reason: :feature_unavailable
        )
      end

      token_response = create_access_token
      if token_response.error?
        return ServiceResponse.error(
          message: 'Failed to create access token',
          reason: :token_creation_failed
        )
      end

      access_token = token_response.payload[:access_token].token
      registration_input = {
        project_id: project.id,
        project_name: project.name,
        project_namespace: project.namespace.full_path,
        access_token: access_token
      }
      result = ::Gitlab::AppliedMl::SuggestedReviewers::Client.new.register_project(**registration_input)

      ServiceResponse.success(payload: result)
    rescue Gitlab::AppliedMl::Errors::ProjectAlreadyExists
      ServiceResponse.error(message: 'Project is already registered', reason: :project_already_registered)
    rescue Gitlab::AppliedMl::Errors::ResourceNotAvailable
      ServiceResponse.error(message: 'Failed to register project', reason: :client_request_failed)
    end

    private

    def project_registration_available?
      project.suggested_reviewers_available? &&
        project.suggested_reviewers_enabled &&
        current_user.can?(:create_resource_access_tokens, project)
    end

    def create_access_token
      token_params = {
        name: 'Suggested reviewers token',
        scopes: [Gitlab::Auth::READ_API_SCOPE],
        expires_at: 95.days.from_now
      }

      ResourceAccessTokens::CreateService.new(current_user, project, token_params).execute
    end
  end
end
