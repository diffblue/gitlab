# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::InsightsController, feature_category: :value_stream_management do
  let_it_be(:parent_group) { create(:group, :private) }
  let_it_be(:nested_group) { create(:group, :private, parent: parent_group) }
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:insight) { create(:insight, group: parent_group, project: project) }
  let_it_be(:user) { create(:user) }

  let(:projects_params) { { only: [project.id, project.full_path] } }
  let(:params) { { group_id: parent_group } }

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
    stub_licensed_features(insights: true, dora4_analytics: true)
    sign_in(user)
    parent_group.add_developer(user)
    nested_group.add_developer(user)
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
    context 'when visiting the parent group' do
      describe 'GET #show.html' do
        subject { get :show, params: params.merge(group_id: parent_group.to_param) }

        it_behaves_like '404 status'
      end

      describe 'GET #show.json' do
        subject { get :show, params: params.merge(group_id: parent_group.to_param), format: :json }

        it_behaves_like '404 status'
      end

      describe 'POST #query' do
        subject { post :query, params: params.merge(query_params.merge(group_id: parent_group.to_param)) }

        it_behaves_like '404 status'
      end
    end

    context 'when visiting a nested group' do
      describe 'GET #show.html' do
        subject { get :show, params: params.merge(group_id: nested_group.to_param) }

        # The following expectation should be changed to
        # it_behaves_like '404 status'
        # once https://gitlab.com/gitlab-org/gitlab/issues/11340 is implemented.
        it_behaves_like '200 status'
      end

      describe 'GET #show.json' do
        subject { get :show, params: params.merge(group_id: nested_group.to_param), format: :json }

        # The following expectation should be changed to
        # it_behaves_like '404 status'
        # once https://gitlab.com/gitlab-org/gitlab/issues/11340 is implemented.
        it_behaves_like '200 status'

        # The following expectation should be removed
        # once https://gitlab.com/gitlab-org/gitlab/issues/11340 is implemented.
        it 'does return the default config' do
          subject

          expect(response.parsed_body).to eq(parent_group.default_insights_config.as_json)
        end
      end

      describe 'POST #query.json' do
        subject { post :query, params: params.merge(query_params.merge(group_id: nested_group.to_param)), format: :json }

        # The following expectation should be changed to
        # it_behaves_like '404 status'
        # once https://gitlab.com/gitlab-org/gitlab/issues/11340 is implemented.
        it_behaves_like '200 status'
      end
    end
  end

  context 'when insights configuration project can be read by current user' do
    before do
      project.add_reporter(user)
    end

    context 'when the configuration is attached to the current group' do
      describe 'GET #show.html' do
        subject { get :show, params: params.merge(group_id: parent_group.to_param) }

        it_behaves_like '200 status'
      end

      describe 'GET #show.json' do
        subject { get :show, params: params.merge(group_id: parent_group.to_param), format: :json }

        it_behaves_like '200 status'
      end

      describe 'POST #query.json' do
        subject { post :query, params: params.merge(query_params.merge(group_id: parent_group.to_param)), format: :json }

        it_behaves_like '200 status'
      end

      describe 'GET #show' do
        it_behaves_like 'tracking unique visits', :show do
          let(:request_params) { params.merge(group_id: parent_group.to_param) }
          let(:target_id) { 'g_analytics_insights' }
        end

        it_behaves_like 'Snowplow event tracking with RedisHLL context', overrides: { project: nil } do
          subject { get :show, params: params.merge(group_id: parent_group.to_param) }

          let(:category) { described_class.name }
          let(:action) { 'perform_analytics_usage_action' }
          let(:label) { 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly' }
          let(:property) { 'g_analytics_insights' }
          let(:namespace) { parent_group }
        end
      end
    end

    context 'when the configuration is attached to a nested group' do
      describe 'GET #show.html' do
        subject { get :show, params: params.merge(group_id: nested_group.to_param) }

        it_behaves_like '200 status'
      end

      describe 'GET #show.json' do
        subject { get :show, params: params.merge(group_id: nested_group.to_param), format: :json }

        it_behaves_like '200 status'
      end

      describe 'POST #query.json' do
        subject { post :query, params: params.merge(query_params.merge(group_id: nested_group.to_param)), format: :json }

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
    end
  end
end
