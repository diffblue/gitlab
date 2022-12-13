# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Analytics::GroupActivityAnalytics, feature_category: :value_stream_management do
  let_it_be(:group) { create(:group, :private) }

  let_it_be(:reporter) do
    create(:user).tap { |u| group.add_reporter(u) }
  end

  let_it_be(:anonymous_user) { create(:user) }

  shared_examples 'GET group_activity' do |activity, count|
    let(:feature_available) { true }
    let(:params) { { group_path: group.full_path } }
    let(:current_user) { reporter }
    let(:request) do
      get api("/analytics/group_activity/#{activity}_count", current_user), params: params
    end

    before do
      stub_licensed_features(group_activity_analytics: feature_available)

      request
    end

    context 'when feature is enabled for a group' do
      it 'is successful' do
        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'is returns a count' do
        expect(response.parsed_body).to eq({ "#{activity}_count" => count })
      end
    end

    context 'when feature is not available in plan' do
      let(:feature_available) { false }

      it 'is returns `forbidden`' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when `group_path` is not specified' do
      let(:params) {}

      it 'returns `bad_request`' do
        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when name is made of only digits' do
      let_it_be(:group) { create(:group, :private, name: '756125') }

      let_it_be(:reporter) do
        create(:user).tap { |u| group.add_reporter(u) }
      end

      it 'is successful' do
        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'is returns a count' do
        expect(response.parsed_body).to eq({ "#{activity}_count" => count })
      end
    end

    context 'when user does not have access to a group' do
      let(:current_user) { anonymous_user }

      it 'is returns `not_found`' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  context 'GET /group_activity/issues_count' do
    it_behaves_like 'GET group_activity', 'issues', 0
  end

  context 'GET /group_activity/merge_requests_count' do
    it_behaves_like 'GET group_activity', 'merge_requests', 0
  end

  context 'GET /group_activity/new_members_count' do
    it_behaves_like 'GET group_activity', 'new_members', 1 # reporter
  end
end
