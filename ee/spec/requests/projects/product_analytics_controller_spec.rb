# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProductAnalyticsController, type: :request do
  describe 'GET /:namespace/:project/-/product_analytics/dashboards' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { project.first_owner }

    before do
      stub_feature_flags(product_analytics_internal_preview: true)
      stub_licensed_features(product_analytics: true)

      login_as(user)
    end

    shared_examples 'returns not found' do
      it 'returns 404 response' do
        send_dashboards_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it 'returns 200 response' do
      send_dashboards_request

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'with feature flag disabled' do
      before do
        stub_feature_flags(product_analytics_internal_preview: false)
        stub_licensed_features(product_analytics: true)
      end

      it_behaves_like 'returns not found'
    end

    context 'without licensed feature' do
      before do
        stub_feature_flags(product_analytics_internal_preview: true)
        stub_licensed_features(product_analytics: false)
      end

      it_behaves_like 'returns not found'
    end

    def send_dashboards_request
      get project_product_analytics_dashboards_path(project)
    end
  end
end
