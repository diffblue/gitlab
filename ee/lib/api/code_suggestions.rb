# frozen_string_literal: true

module API
  class CodeSuggestions < ::API::Base
    feature_category :code_suggestions

    before do
      authenticate!
      check_feature_enabled!
      check_user_allowed!
    end

    helpers do
      def check_feature_enabled!
        not_found! unless Feature.enabled?(:code_suggestions_tokens_api, type: :ops)
      end

      def check_user_allowed!
        # Check if the feature is disabled for any of the user's groups
        accessible_root_groups = current_user.groups.by_parent(nil)
        code_suggestions_disabled_by_group = accessible_root_groups.reject(&:code_suggestions_enabled?).any?

        # Check if the feature is disabled by the user
        return if !code_suggestions_disabled_by_group && current_user.code_suggestions_enabled?

        unauthorized!('Code Suggestions is disabled for user')
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
          token = Gitlab::CodeSuggestions::AccessToken.new
          present token, with: Entities::CodeSuggestionsAccessToken
        end
      end
    end
  end
end
