# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Analytics::ProductAnalytics do
  let_it_be(:project) { create(:project) }

  let(:current_user) { project.owner }

  describe 'POST projects/:id/product_analytics/request' do
    before do
      stub_cube_load
      stub_ee_application_setting(cube_api_key: 'testtest')
      stub_ee_application_setting(cube_api_base_url: 'http://cube.dev')
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(cube_api_proxy: false)
      end

      it 'returns a 404' do
        post api("/projects/#{project.id}/product_analytics/request", current_user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when current user has guest project access' do
      let_it_be(:current_user) { create(:user) }

      before do
        project.add_guest(current_user)
      end

      it 'returns an unauthorized error' do
        post api("/projects/#{project.id}/product_analytics/request", current_user)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when current user is a project developer' do
      let_it_be(:current_user) { create(:user) }

      before do
        project.add_developer(current_user)
      end

      it 'returns a 201' do
        post api("/projects/#{project.id}/product_analytics/request", current_user)

        expect(response).to have_gitlab_http_status(:created)
      end
    end

    context 'when cube_api_base_url application setting is not set' do
      before do
        stub_ee_application_setting(cube_api_base_url: nil)
      end

      it 'returns a 404' do
        post api("/projects/#{project.id}/product_analytics/request", current_user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when cube_api_key application setting is not set' do
      before do
        stub_ee_application_setting(cube_api_key: nil)
      end

      it 'returns a 404' do
        post api("/projects/#{project.id}/product_analytics/request", current_user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  private

  def stub_cube_load
    stub_request(:post, "http://cube.dev/cubejs-api/v1/load")
      .to_return(status: 201, body: "{}", headers: {})
  end
end
