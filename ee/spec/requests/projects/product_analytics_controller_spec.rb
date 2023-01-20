# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProductAnalyticsController, type: :request, feature_category: :product_analytics do
  describe 'GET /:namespace/:project/-/product_analytics/dashboards' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { project.first_owner }

    before do
      stub_feature_flags(product_analytics_internal_preview: true)
      stub_licensed_features(product_analytics: true)
      stub_application_setting(jitsu_host: 'https://jitsu.example.com')
      stub_application_setting(jitsu_project_xid: '123')
      stub_application_setting(jitsu_administrator_email: 'test@example.com')
      stub_application_setting(jitsu_administrator_password: 'password')
      stub_application_setting(product_analytics_clickhouse_connection_string: 'clickhouse://localhost:9000')
      stub_application_setting(cube_api_base_url: 'https://cube.example.com')
      stub_application_setting(cube_api_key: '123')
      stub_application_setting(product_analytics_enabled: true)
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

    context 'without multiple settings' do
      before do
        stub_application_setting(jitsu_host: nil)
        stub_licensed_features(product_analytics: false)
      end

      it_behaves_like 'returns not found'
    end

    context 'without jitsu_host application setting' do
      before do
        stub_application_setting(jitsu_host: nil)
      end

      it_behaves_like 'returns not found'
    end

    context 'when product_analytics_enabled application setting is false' do
      before do
        stub_application_setting(product_analytics_enabled: false)
      end

      it_behaves_like 'returns not found'
    end

    context 'without jitsu_project_xid application setting' do
      before do
        stub_application_setting(jitsu_project_xid: nil)
      end

      it_behaves_like 'returns not found'
    end

    context 'without jitsu_administrator_email application setting' do
      before do
        stub_application_setting(jitsu_administrator_email: nil)
      end

      it_behaves_like 'returns not found'
    end

    context 'without jitsu_administrator_password application setting' do
      before do
        stub_application_setting(jitsu_administrator_password: nil)
      end

      it_behaves_like 'returns not found'
    end

    context 'without product_analytics_clickhouse_connection_string application setting' do
      before do
        stub_application_setting(product_analytics_clickhouse_connection_string: nil)
      end

      it_behaves_like 'returns not found'
    end

    context 'without cube_api_base_url application setting' do
      before do
        stub_application_setting(cube_api_base_url: nil)
      end

      it_behaves_like 'returns not found'
    end

    context 'without cube_api_key application setting' do
      before do
        stub_application_setting(cube_api_key: nil)
      end

      it_behaves_like 'returns not found'
    end

    def send_dashboards_request
      get project_product_analytics_dashboards_path(project)
    end
  end
end
