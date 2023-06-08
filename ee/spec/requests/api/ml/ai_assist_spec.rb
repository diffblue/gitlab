# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ml::AiAssist, feature_category: :code_suggestions do
  let(:current_user) { nil }
  let(:api_feature_flag) { true }
  let(:plan) { nil }
  let(:group_code_suggestions_setting) { true }
  let(:user_code_suggestions_setting) { false }
  let(:third_party_ai_features_enabled) { false }

  let(:group_user) do
    create(:user).tap do |record|
      record.update_attribute(:code_suggestions, user_code_suggestions_setting)
    end
  end

  let(:allowed_group) do
    create(:group_with_plan, plan: plan).tap do |record|
      record.add_owner(group_user)
      record.update_attribute(:code_suggestions, group_code_suggestions_setting)
      record.update_attribute(:third_party_ai_features_enabled, third_party_ai_features_enabled)
    end
  end

  describe 'GET /ml/ai-assist user_is_allowed' do
    using RSpec::Parameterized::TableSyntax

    before do
      stub_feature_flags(ai_assist_flag: feature_flag)
      stub_feature_flags(ai_assist_api: api_feature_flag)
    end

    subject(:get_api) { get api('/ml/ai-assist', current_user) }

    context 'when user not logged in' do
      let(:current_user) { nil }

      where(:feature_flag, :result) do
        false | :unauthorized
        true  | :unauthorized
      end

      with_them do
        it 'returns unauthorized' do
          get_api

          expect(response).to have_gitlab_http_status(result)
        end
      end
    end

    context 'when user is logged in' do
      let(:current_user) { create(:user) }

      where(:feature_flag, :result) do
        false | :not_found
        true  | :not_found
      end

      with_them do
        it 'returns not found' do
          get_api

          expect(response).to have_gitlab_http_status(result)
        end
      end
    end

    context 'when user is logged in and in group, with group and user code_suggestions enabled' do
      let(:current_user) { group_user }
      let(:user_code_suggestions_setting) { true }

      where(:feature_flag, :third_party_ai_features_enabled, :result, :body) do
        false | false | :not_found | { "message" => "404 Not Found" }
        true  | false | :ok        | { "third_party_ai_features_enabled" => false, "user_is_allowed" => true }
        true  | true  | :ok        | { "third_party_ai_features_enabled" => true, "user_is_allowed" => true }
      end

      with_them do
        it 'returns not found except when both flags true' do
          allowed_group

          get_api

          expect(response).to have_gitlab_http_status(result)
          expect(json_response).to eq(body)
        end
      end
    end

    context 'when code_suggestions setting is false for group' do
      let(:group_code_suggestions_setting) { false }
      let(:current_user) { group_user }

      where(:feature_flag, :user_code_suggestions_setting, :result, :body) do
        false |  false | :not_found | { "message" => "404 Not Found" }
        true  |  false | :not_found | { "message" => "404 Not Found" }
        false |  true  | :not_found | { "message" => "404 Not Found" }
        true  |  true  | :not_found | { "message" => "404 Not Found" }
      end

      with_them do
        it 'returns not found' do
          allowed_group

          get_api

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
        false |  false | :not_found | { "message" => "404 Not Found" }
        true  |  false | :not_found | { "message" => "404 Not Found" }
        false |  true  | :not_found | { "message" => "404 Not Found" }
        true  |  true  | :not_found | { "message" => "404 Not Found" }
      end

      with_them do
        it 'returns not found if any group disables code suggestions' do
          disallowed_group
          allowed_group

          get_api

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

      where(:feature_flag, :result, :body) do
        false | :not_found | { "message" => "404 Not Found" }
        true  | :ok        | { "third_party_ai_features_enabled" => false, "user_is_allowed" => true }
      end

      with_them do
        it 'returns not found except when both flags true' do
          get_api

          expect(response).to have_gitlab_http_status(result)
          expect(json_response).to eq(body)
        end
      end
    end

    context 'when code_suggestions setting is false for user' do
      let(:current_user) do
        create(:user).tap do |record|
          record.update_attribute(:code_suggestions, false)
        end
      end

      where(:feature_flag, :result, :body) do
        false | :not_found | { "message" => "404 Not Found" }
        true  | :not_found | { "message" => "404 Not Found" }
      end

      with_them do
        it 'returns not found' do
          get_api

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
          get_api

          expect(response).to have_gitlab_http_status(result)
          expect(json_response).to eq(body)
        end
      end
    end
  end
end
