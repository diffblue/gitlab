# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Analytics::CodeReviewsController, type: :request, feature_category: :value_stream_management do
  let(:user) { create :user }
  let(:project) { create(:project) }

  before do
    login_as user
  end

  describe 'GET /*namespace_id/:project_id/analytics/code_reviews' do
    context 'for reporter+' do
      before do
        project.add_reporter(user)
      end

      context 'with code_review_analytics included in plan' do
        it 'is success' do
          get project_analytics_code_reviews_path(project)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'without code_review_analytics in plan' do
        before do
          stub_licensed_features(code_review_analytics: false)
        end

        it 'is not found' do
          get project_analytics_code_reviews_path(project)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'for guests' do
      before do
        project.add_guest(user)
      end

      it 'is not found' do
        get project_analytics_code_reviews_path(project)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end

RSpec.describe Projects::Analytics::CodeReviewsController, type: :controller do
  let(:user) { create :user }
  let(:project) { create(:project) }

  before do
    sign_in user
    project.add_reporter(user)
  end

  it_behaves_like 'tracking unique visits', :index do
    let(:request_params) { { namespace_id: project.namespace, project_id: project } }
    let(:target_id) { 'p_analytics_code_reviews' }
  end

  it_behaves_like 'Snowplow event tracking with RedisHLL context' do
    subject { get :index, params: request_params, format: :html }

    let(:request_params) { { namespace_id: project.namespace, project_id: project } }
    let(:category) { described_class.name }
    let(:action) { 'perform_analytics_usage_action' }
    let(:namespace) { project.namespace }
    let(:label) { 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly' }
    let(:property) { 'p_analytics_code_reviews' }
  end
end
