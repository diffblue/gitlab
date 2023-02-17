# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::InsightsController, feature_category: :value_stream_management do
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:project) { create(:project, :private, namespace: group) }
  let_it_be(:insight) { create(:insight, group: group, project: project) }
  let_it_be(:user) { create(:user) }

  let(:projects_params) { { only: [project.id, project.full_path] } }
  let(:params) { { project_id: project, namespace_id: group } }

  let(:query_params) do
    {
      type: 'bar',
      query: {
        data_source: 'issuables',
        params: {
          issuable_type: 'issue',
          collection_labels: ['bug']
        },
        projects: projects_params
      }
    }
  end

  before do
    stub_licensed_features(insights: true)
    sign_in(user)
  end

  shared_examples '404 status' do
    it 'returns 404 status' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples '200 status' do
    it 'returns 200 status' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  context 'when insights configuration project cannot be read by current user' do
    describe 'GET #show.html' do
      subject { get :show, params: params }

      it_behaves_like '404 status'
    end

    describe 'GET #show.json' do
      subject { get :show, params: params, format: :json }

      it_behaves_like '404 status'
    end

    describe 'POST #query' do
      subject { post :query, params: params.merge(query_params) }

      it_behaves_like '404 status'
    end
  end

  context 'when insights configuration project can be read by current user' do
    before do
      project.add_reporter(user)
    end

    describe 'GET #show.html' do
      subject { get :show, params: params }

      it_behaves_like '200 status'
    end

    describe 'GET #show.json' do
      subject { get :show, params: params, format: :json }

      it_behaves_like '200 status'
    end

    describe 'POST #query.json' do
      subject { post :query, params: params.merge(query_params), format: :json }

      it_behaves_like '200 status'

      context 'when using the legacy format' do
        let(:query_params) do
          {
            type: 'bar',
            query: { issuable_type: 'issue', collection_labels: ['bug'] },
            projects: projects_params
          }
        end

        it_behaves_like '200 status'
      end
    end

    describe 'GET #show' do
      it_behaves_like 'tracking unique visits', :show do
        let(:request_params) { params }
        let(:target_id) { 'p_analytics_insights' }
      end

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        subject { get :show, params: params, format: :html }

        let(:category) { described_class.name }
        let(:action) { 'perform_analytics_usage_action' }
        let(:namespace) { group }
        let(:label) { 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly' }
        let(:property) { 'p_analytics_insights' }
      end
    end
  end
end
