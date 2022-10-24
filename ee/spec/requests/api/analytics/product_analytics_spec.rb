# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Analytics::ProductAnalytics do
  let_it_be(:project) { create(:project) }

  let(:current_user) { project.owner }
  let(:cube_api_url) { "http://cube.dev/cubejs-api/v1/load" }

  shared_examples 'a not found error' do
    it 'returns a 404' do
      get api("/projects/#{project.id}/product_analytics/request/load", current_user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET projects/:id/product_analytics/request/load' do
    before do
      stub_cube_load
      stub_licensed_features(product_analytics: true)
      stub_ee_application_setting(product_analytics_enabled: true)
      stub_ee_application_setting(cube_api_key: 'testtest')
      stub_ee_application_setting(cube_api_base_url: 'http://cube.dev')
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(cube_api_proxy: false)
      end

      it 'returns a 404' do
        get api("/projects/#{project.id}/product_analytics/request/load", current_user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when feature is unlicensed' do
      before do
        stub_licensed_features(product_analytics: false)
      end

      it_behaves_like 'a not found error'
    end

    context 'when current user has guest project access' do
      let_it_be(:current_user) { create(:user) }

      before do
        project.add_guest(current_user)
      end

      it 'returns an unauthorized error' do
        get api("/projects/#{project.id}/product_analytics/request/load", current_user)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when current user is a project developer' do
      let_it_be(:current_user) { create(:user) }

      before do
        project.add_developer(current_user)
      end

      it 'returns a 200' do
        get api("/projects/#{project.id}/product_analytics/request/load", current_user)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'only passes on predefined parameters' do
        params = {
          query: { measures: ['Jitsu.count'] }.to_json,
          'queryType': 'multi',
          'badParam': 1
        }.to_query
        get api("/projects/#{project.id}/product_analytics/request/load?#{params}", current_user)

        expect(WebMock).to have_requested(:post, cube_api_url).with(
          body: { query: { measures: ['Jitsu.count'] }, 'queryType': 'multi' }.to_json
        )
      end
    end

    context 'when cube_api_base_url application setting is not set' do
      before do
        stub_ee_application_setting(cube_api_base_url: nil)
      end

      it_behaves_like 'a not found error'
    end

    context 'when cube_api_key application setting is not set' do
      before do
        stub_ee_application_setting(cube_api_key: nil)
      end

      it_behaves_like 'a not found error'
    end

    context 'when enable_product_analytics application setting is false' do
      before do
        stub_ee_application_setting(product_analytics_enabled: false)
      end

      it 'returns a 404' do
        post api("/projects/#{project.id}/product_analytics/request", current_user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  private

  def stub_cube_load
    stub_request(:post, cube_api_url)
      .to_return(status: 201, body: "{}", headers: {})
  end
end
