# frozen_string_literal: true

module API
  class CodeSuggestions < ::API::Base
    feature_category :code_suggestions

    helpers ::API::Helpers::AiProxyHelper

    before do
      authenticate!

      not_found! unless Feature.enabled?(:code_suggestions_tokens_api, type: :ops)
      unauthorized! unless user_allowed?
    end

    helpers do
      def user_allowed?
        current_user.can?(:access_code_suggestions) && access_code_suggestions_when_proxied_to_saas?
      end

      def model_gateway_headers(headers)
        token = headers["X-Gitlab-Oidc-Token"]

        telemetry_headers = {
          'X-GitLab-CS-Accepts' => headers['X-Gitlab-Cs-Accepts'],
          'X-GitLab-CS-Requests' => headers['X-Gitlab-Cs-Requests'],
          'X-GitLab-CS-Errors' => headers['X-Gitlab-Cs-Errors']
        }.compact

        {
          'X-Gitlab-Authentication-Type' => 'oidc',
          'Authorization' => "Bearer #{token}",
          'Content-Type' => 'application/json'
        }.merge(telemetry_headers)
      end

      # In case the request was proxied from the self-managed instance,
      # we have an extra check on Gitlab.com if FF is enabled for self-managed admin.
      # The FF is used for gradual rollout for handpicked self-managed customers interested to use code suggestions.
      def access_code_suggestions_when_proxied_to_saas?
        proxied = proxied?

        raise 'Proxying is only supported under .org or .com' if proxied && !Gitlab.org_or_com?

        !proxied || Feature.enabled?(:code_suggestions_for_instance_admin_enabled, current_user)
      end

      def proxied?
        !!request.headers['User-Agent']&.starts_with?('gitlab-workhorse')
      end

      def gitlab_realm
        return Gitlab::CodeSuggestions::AccessToken::GITLAB_REALM_SELF_MANAGED if proxied?

        Gitlab::CodeSuggestions::AccessToken::GITLAB_REALM_SAAS
      end
    end

    namespace 'code_suggestions' do
      resources :tokens do
        desc 'Create an access token' do
          detail 'Creates an access token to access Code Suggestions.'
          success Entities::CodeSuggestionsAccessToken
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
        end
        post do
          with_proxy_ai_request do
            Gitlab::Tracking.event(
              'API::CodeSuggestions',
              :authenticate,
              user: current_user,
              label: 'code_suggestions'
            )

            token = Gitlab::CodeSuggestions::AccessToken.new(current_user, gitlab_realm: gitlab_realm)
            present token, with: Entities::CodeSuggestionsAccessToken
          end
        end
      end

      resources :completions do
        post do
          not_found! unless ::Feature.enabled?(:code_suggestions_completion_api, current_user)

          response = ::Gitlab::HTTP.post('https://codesuggestions.gitlab.com/v2/completions', {
            body: params.except(:private_token).to_json,
            headers: model_gateway_headers(headers),
            open_timeout: 3,
            read_timeout: 5,
            write_timeout: 5
          })
          status response.code
          response
        end
      end
    end
  end
end
