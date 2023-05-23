# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::CodeSuggestions, feature_category: :code_suggestions do
  using RSpec::Parameterized::TableSyntax

  let(:current_user) { nil }
  let(:api_feature_flag) { true }
  let(:plan) { nil }
  let(:group_code_suggestions_setting) { true }
  let(:user_code_suggestions_setting) { false }

  let(:group_user) do
    create(:user).tap do |record|
      record.update_attribute(:code_suggestions, user_code_suggestions_setting)
    end
  end

  let(:allowed_group) do
    create(:group_with_plan, plan: plan).tap do |record|
      record.add_owner(group_user)
      record.update_attribute(:code_suggestions, group_code_suggestions_setting)
    end
  end

  shared_examples 'a successful response' do
    it 'returns created', :freeze_time, :aggregate_failures do
      created_at = Time.now.to_i

      post_api

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response).to include(
        'access_token' => kind_of(String),
        'expires_in' => Gitlab::CodeSuggestions::AccessToken::EXPIRES_IN,
        'created_at' => created_at
      )
    end
  end

  describe 'POST /code_suggestions/tokens' do
    before do
      stub_feature_flags(ai_assist_flag: feature_flag)
      stub_feature_flags(code_suggestions_tokens_api: api_feature_flag)
    end

    subject(:post_api) { post api('/code_suggestions/tokens', current_user) }

    context 'when user is not logged in' do
      let(:current_user) { nil }

      where(:feature_flag, :result) do
        false | :unauthorized
        true  | :unauthorized
      end

      with_them do
        it 'returns unauthorized' do
          post_api

          expect(response).to have_gitlab_http_status(result)
        end
      end
    end

    context 'when user is logged in' do
      let(:current_user) { create(:user) }

      where(:feature_flag, :result, :body) do
        false | :unauthorized | { "message" => "401 Unauthorized - Code Suggestions is disabled for user" }
        true  | :unauthorized | { "message" => "401 Unauthorized - Code Suggestions is disabled for user" }
      end

      with_them do
        it 'returns unauthorized' do
          post_api

          expect(response).to have_gitlab_http_status(result)
          expect(json_response).to eq(body)
        end
      end
    end

    context 'when user is logged in and in group, with group and user code_suggestions enabled' do
      let(:current_user) { group_user }
      let(:user_code_suggestions_setting) { true }

      context 'when feature flag is false' do
        let(:feature_flag) { false }

        it 'returns unauthorized' do
          allowed_group

          post_api

          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(json_response).to eq("message" => "401 Unauthorized - Code Suggestions is disabled for user")
        end
      end

      context 'when feature flag is true' do
        let(:feature_flag) { true }

        it_behaves_like 'a successful response'
      end
    end

    context 'when code_suggestions setting is false for group' do
      let(:group_code_suggestions_setting) { false }
      let(:current_user) { group_user }

      where(:feature_flag, :user_code_suggestions_setting, :result, :body) do
        false | false | :unauthorized | { "message" => "401 Unauthorized - Code Suggestions is disabled for user" }
        true  | false | :unauthorized | { "message" => "401 Unauthorized - Code Suggestions is disabled for user" }
        false | true  | :unauthorized | { "message" => "401 Unauthorized - Code Suggestions is disabled for user" }
        true  | true  | :unauthorized | { "message" => "401 Unauthorized - Code Suggestions is disabled for user" }
      end

      with_them do
        it 'returns not found' do
          allowed_group

          post_api

          expect(response).to have_gitlab_http_status(result)
          expect(json_response).to eq(body)
        end
      end
    end

    context 'when code_suggestions setting is false for one group, true for another' do
      let(:group_code_suggestions_setting) { true }
      let(:current_user) { group_user }
      let(:disallowed_group) do
        create(:group_with_plan, plan: plan).tap do |record|
          record.add_owner(group_user)
          record.update_attribute(:code_suggestions, false)
        end
      end

      where(:feature_flag, :user_code_suggestions_setting, :result, :body) do
        false | false | :unauthorized | { "message" => "401 Unauthorized - Code Suggestions is disabled for user" }
        true  | false | :unauthorized | { "message" => "401 Unauthorized - Code Suggestions is disabled for user" }
        false | true  | :unauthorized | { "message" => "401 Unauthorized - Code Suggestions is disabled for user" }
        true  | true  | :unauthorized | { "message" => "401 Unauthorized - Code Suggestions is disabled for user" }
      end

      with_them do
        it 'returns not found if any group disables code suggestions' do
          disallowed_group
          allowed_group

          post_api

          expect(response).to have_gitlab_http_status(result)
          expect(json_response).to eq(body)
        end
      end
    end

    context 'when code_suggestions setting is true for user' do
      let(:current_user) do
        create(:user).tap do |record|
          record.update_attribute(:code_suggestions, true)
        end
      end

      context 'when feature flag is false' do
        let(:feature_flag) { false }

        it 'returns unauthorized' do
          allowed_group

          post_api

          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(json_response).to eq("message" => "401 Unauthorized - Code Suggestions is disabled for user")
        end
      end

      context 'when feature flag is true' do
        let(:feature_flag) { true }

        it_behaves_like 'a successful response'
      end
    end

    context 'when code_suggestions setting is false for user' do
      let(:current_user) do
        create(:user).tap do |record|
          record.update_attribute(:code_suggestions, false)
        end
      end

      where(:feature_flag, :result, :body) do
        false | :unauthorized | { "message" => "401 Unauthorized - Code Suggestions is disabled for user" }
        true  | :unauthorized | { "message" => "401 Unauthorized - Code Suggestions is disabled for user" }
      end

      with_them do
        it 'returns unauthorized' do
          post_api

          expect(response).to have_gitlab_http_status(result)
          expect(json_response).to eq(body)
        end
      end
    end

    context 'when API feature flag is disabled' do
      let(:current_user) { group_user }
      let(:api_feature_flag) { false }

      where(:feature_flag, :result, :body) do
        false | :not_found | { "message" => "404 Not Found" }
        true  | :not_found | { "message" => "404 Not Found" }
      end

      with_them do
        it 'returns not found' do
          post_api

          expect(response).to have_gitlab_http_status(result)
          expect(json_response).to eq(body)
        end
      end
    end
  end
end
