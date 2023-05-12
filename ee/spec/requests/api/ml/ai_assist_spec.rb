# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ml::AiAssist, feature_category: :code_suggestions do
  let(:current_user) { nil }
  let(:api_feature_flag) { true }
  let_it_be(:user) { create(:user) }
  let_it_be(:group_user) { create(:user) }
  let_it_be(:allowed_group) do
    create(:group).tap do |record|
      record.add_owner(group_user)
      record.update_attribute(:code_suggestions, true)
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
      let(:current_user) { user }

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

    context 'when user is logged in and in group' do
      let(:current_user) { group_user }

      where(:feature_flag, :result, :body) do
        false | :not_found | { "message" => "404 Not Found" }
        true  | :ok        | { "user_is_allowed" => true }
      end

      with_them do
        it 'returns not found except when both flags true' do
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
