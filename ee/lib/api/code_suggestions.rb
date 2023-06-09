# frozen_string_literal: true

module API
  class CodeSuggestions < ::API::Base
    feature_category :code_suggestions

    before do
      authenticate!

      not_found! unless Feature.enabled?(:code_suggestions_tokens_api, type: :ops)
      unauthorized! unless current_user.can?(:access_code_suggestions)
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
          token = Gitlab::CodeSuggestions::AccessToken.new(current_user)
          present token, with: Entities::CodeSuggestionsAccessToken
        end
      end
    end
  end
end
