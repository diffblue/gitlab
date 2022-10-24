# frozen_string_literal: true

module Projects
  class RegisterSuggestedReviewersProjectService < BaseProjectService
    def execute
      return unless project.suggested_reviewers_available? && project.suggested_reviewers_enabled
      return unless current_user.can?(:create_resource_access_tokens, project)

      registration_input = {
        project_id: project.id,
        project_name: project.name,
        project_namespace: project.namespace.full_path,
        access_token: access_token
      }
      result = ::Gitlab::AppliedMl::SuggestedReviewers::Client.new.register_project(**registration_input)
      success(result)
    end

    private

    def access_token
      token_params = {
        name: 'Suggested reviewers token',
        scopes: [Gitlab::Auth::READ_API_SCOPE],
        expires_at: 95.days.from_now
      }

      token_response = ResourceAccessTokens::CreateService.new(current_user, project, token_params).execute
      token_response.payload[:access_token].token
    end
  end
end
