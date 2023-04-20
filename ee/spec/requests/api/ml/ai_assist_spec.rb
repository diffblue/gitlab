# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ml::AiAssist, :saas, feature_category: :code_suggestions do
  let_it_be(:user) { create(:user) }
  let_it_be(:group_user) { create(:user) }
  let(:current_user) { nil }
  let(:plan) { nil }
  let(:api_feature_flag) { true }

  let(:allowed_group) do
    create(:group_with_plan, plan: plan).tap do |record|
      record.add_owner(group_user)
      record.update_attribute(:code_suggestions, true)
    end
  end

  describe 'GET /ml/ai-assist user_is_allowed' do
    using RSpec::Parameterized::TableSyntax

    before do
      stub_licensed_features(ai_assist: license_flag)
      stub_feature_flags(ai_assist_flag: feature_flag)
      stub_feature_flags(ai_assist_api: api_feature_flag)
    end

    subject { get api('/ml/ai-assist', current_user) }

    context 'when user not logged in' do
      let(:current_user) { nil }

      where(:feature_flag, :license_flag, :result) do
        false | false | :unauthorized
        true | false | :unauthorized
        false | true | :unauthorized
        true | true | :unauthorized
      end

      with_them do
        it 'returns unauthorized' do
          subject
          expect(response).to have_gitlab_http_status(result)
        end
      end
    end

    context 'when user is logged in' do
      let(:current_user) { user }

      where(:feature_flag, :license_flag, :result) do
        false | false | :not_found
        true | false | :not_found
        false | true | :not_found
        true | true | :not_found
      end

      with_them do
        it 'returns not found' do
          subject
          expect(response).to have_gitlab_http_status(result)
        end
      end
    end

    context 'when user is logged in and in group' do
      let(:current_user) { group_user }

      where(:feature_flag, :license_flag, :plan, :result, :body) do
        false | true | nil | :not_found | { "message" => "404 Not Found" }
        false | false | nil | :not_found | { "message" => "404 Not Found" }
        true  | true | nil | :ok | { "user_is_allowed" => false }
        true  | false | nil | :ok | { "user_is_allowed" => false }
        false | true | :premium_plan | :not_found | { "message" => "404 Not Found" }
        false | false | :premium_plan | :not_found | { "message" => "404 Not Found" }
        true  | true | :premium_plan | :ok | { "user_is_allowed" => true }
        true  | false | :premium_plan | :ok | { "user_is_allowed" => true }
        false | true | :ultimate_plan | :not_found | { "message" => "404 Not Found" }
        false | false | :ultimate_plan | :not_found | { "message" => "404 Not Found" }
        true  | true | :ultimate_plan | :ok | { "user_is_allowed" => true }
        true  | false | :ultimate_plan | :ok | { "user_is_allowed" => true }
      end

      with_them do
        it 'returns not found except when both flags true' do
          allowed_group
          subject
          expect(response).to have_gitlab_http_status(result)
          expect(json_response).to eq(body)
        end
      end
    end

    context 'when API feature flag is disabled' do
      let(:current_user) { group_user }
      let(:api_feature_flag) { false }

      where(:feature_flag, :license_flag, :plan, :result, :body) do
        false | true | nil | :not_found | { "message" => "404 Not Found" }
        false | false | nil | :not_found | { "message" => "404 Not Found" }
        true  | true | nil | :not_found | { "message" => "404 Not Found" }
        true  | false | nil | :not_found | { "message" => "404 Not Found" }
        false | true | :premium_plan | :not_found | { "message" => "404 Not Found" }
        false | false | :premium_plan | :not_found | { "message" => "404 Not Found" }
        true  | true | :premium_plan | :not_found | { "message" => "404 Not Found" }
        true  | false | :premium_plan | :not_found | { "message" => "404 Not Found" }
        false | true | :ultimate_plan | :not_found | { "message" => "404 Not Found" }
        false | false | :ultimate_plan | :not_found | { "message" => "404 Not Found" }
        true  | true | :ultimate_plan | :not_found | { "message" => "404 Not Found" }
        true  | false | :ultimate_plan | :not_found | { "message" => "404 Not Found" }
      end
      with_them do
        it 'returns not found' do
          allowed_group
          subject
          expect(response).to have_gitlab_http_status(result)
          expect(json_response).to eq(body)
        end
      end
    end
  end
end
