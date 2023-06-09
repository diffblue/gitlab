# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::CodeSuggestions, feature_category: :code_suggestions do
  let(:current_user) { nil }

  shared_examples 'a response' do |case_name|
    it "returns #{case_name} response", :freeze_time, :aggregate_failures do
      post_api

      expect(response).to have_gitlab_http_status(result)

      expect(json_response).to include(**body)
    end
  end

  shared_examples 'a successful response' do
    include_examples 'a response', 'successful' do
      let(:result) { :created }
      let(:body) do
        {
          'access_token' => kind_of(String),
          'expires_in' => Gitlab::CodeSuggestions::AccessToken::EXPIRES_IN,
          'created_at' => Time.now.to_i
        }
      end
    end
  end

  shared_examples 'an unauthorized response' do
    include_examples 'a response', 'unauthorized' do
      let(:result) { :unauthorized }
      let(:body) do
        { "message" => "401 Unauthorized" }
      end
    end
  end

  describe 'POST /code_suggestions/tokens' do
    let(:headers) { {} }
    let(:access_code_suggestions) { true }

    subject(:post_api) { post api('/code_suggestions/tokens', current_user), headers: headers }

    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?).with(an_instance_of(User), :access_code_suggestions, :global)
         .and_return(access_code_suggestions)
    end

    context 'when user is not logged in' do
      let(:current_user) { nil }

      include_examples 'an unauthorized response'
    end

    context 'when user is logged in' do
      let(:current_user) { create(:user) }

      context 'when API feature flag is disabled' do
        before do
          stub_feature_flags(code_suggestions_tokens_api: false)
        end

        include_examples 'a response', 'not found' do
          let(:result) { :not_found }
          let(:body) do
            { "message" => "404 Not Found" }
          end
        end
      end

      context 'with no access to code suggestions' do
        let(:access_code_suggestions) { false }

        include_examples 'an unauthorized response'
      end

      context 'with access to code suggestions' do
        include_examples 'a successful response'
      end
    end
  end
end
