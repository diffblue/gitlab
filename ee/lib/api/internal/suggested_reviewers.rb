# frozen_string_literal: true

module API
  # Suggested Reviewers Internal API
  module Internal
    class SuggestedReviewers < ::API::Base
      feature_category :workflow_automation

      before do
        check_feature_enabled
        authenticate_gitlab_suggested_reviewers_request!
      end

      helpers do
        def check_feature_enabled
          not_found! unless Feature.enabled?(:suggested_reviewers_internal_api, type: :ops)
        end

        def authenticate_gitlab_suggested_reviewers_request!
          return if Gitlab::AppliedMl::SuggestedReviewers.verify_api_request(headers)

          render_api_error!('Suggested Reviewers JWT authentication invalid', :unauthorized)
        end

        def create_access_token(project)
          token_params = {
            name: 'Suggested reviewers token',
            access_level: Gitlab::Access::REPORTER,
            scopes: [Gitlab::Auth::READ_API_SCOPE],
            expires_at: 1.day.from_now
          }

          ::ResourceAccessTokens::CreateService.new(
            User.suggested_reviewers_bot,
            project,
            token_params
          ).execute
        end
      end

      namespace 'internal' do
        namespace 'suggested_reviewers' do
          resource :tokens do
            desc 'Create a project access token' do
              detail 'Creates a new access token for a project.'
              tags 'project_access_tokens'
              success Entities::ResourceAccessTokenWithToken
              failure [
                { code: 400, message: 'Bad request' },
                { code: 401, message: 'Unauthorized' },
                { code: 404, message: 'Not found' }
              ]
            end
            params do
              requires :project_id, type: Integer, desc: 'The ID of the project'
            end
            post do
              project = find_project(params[:project_id])
              not_found! unless project&.can_suggest_reviewers?

              token_response = create_access_token(project)
              if token_response.success?
                present(
                  token_response.payload[:access_token],
                  with: Entities::ResourceAccessTokenWithToken,
                  resource: project
                )
              else
                bad_request!(token_response.message)
              end
            end
          end
        end
      end
    end
  end
end
