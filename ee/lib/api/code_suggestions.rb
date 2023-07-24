# frozen_string_literal: true

module API
  class CodeSuggestions < ::API::Base
    DEFAULT_CODE_SUGGESTIONS_URL = 'https://codesuggestions.gitlab.com'

    feature_category :code_suggestions

    helpers ::API::Helpers::AiProxyHelper

    PROJECT_CODE_SUGGESTIONS_ADD_ON_CACHE_KEY = 'project-%{project_id}-code-suggestions-add-on-cache'

    before do
      authenticate!

      not_found! unless Feature.enabled?(:code_suggestions_tokens_api, type: :ops)
      unauthorized! unless user_allowed?
    end

    helpers do
      def user_allowed?
        current_user.can?(:access_code_suggestions) && access_code_suggestions_when_proxied_to_saas?
      end

      def active_code_suggestions_purchase?(project_id)
        return false unless project_id
        return true unless ::Feature.enabled?(:purchase_code_suggestions)

        cache_key = format(PROJECT_CODE_SUGGESTIONS_ADD_ON_CACHE_KEY, project_id: project_id)
        Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          ::GitlabSubscriptions::AddOnPurchase.for_project(project_id).for_code_suggestions.active.any?
        end
      end

      def model_gateway_headers(headers)
        telemetry_headers = headers.select { |k| /\Ax-gitlab-cs-/i.match?(k) }

        {
          'X-Gitlab-Authentication-Type' => 'oidc',
          'Authorization' => "Bearer #{headers['X-Gitlab-Oidc-Token']}",
          'Content-Type' => 'application/json'
        }.merge(telemetry_headers).transform_values { |v| Array(v) }
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

      def completions_endpoint
        base_url = ENV.fetch('CODE_SUGGESTIONS_BASE_URL', DEFAULT_CODE_SUGGESTIONS_URL)

        "#{base_url}/v2/completions"
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
          if Gitlab.org_or_com?
            not_found! unless ::Feature.enabled?(:code_suggestions_completion_api, current_user)
            not_found! unless active_code_suggestions_purchase?(params['project_id'])
          else
            not_found! unless ::Feature.enabled?(:self_managed_code_suggestions_completion_api)

            code_suggestions_token = ::Ai::ServiceAccessToken.code_suggestions.active.last
            unauthorized! if code_suggestions_token.nil?

            headers['X-Gitlab-Oidc-Token'] = code_suggestions_token.token
          end

          workhorse_headers =
            Gitlab::Workhorse.send_url(
              completions_endpoint,
              body: params.except(:private_token).to_json,
              headers: model_gateway_headers(headers),
              method: "POST"
            )

          header(*workhorse_headers)

          status :ok
          body ''
        end
      end
    end
  end
end
