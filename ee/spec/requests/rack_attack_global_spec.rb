# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Rack Attack global throttles', feature_category: :system_access do
  include_context 'rack attack cache store'

  context 'when the request is from Geo secondary' do
    let(:project) { create(:project) }
    let(:requests_per_period) { 1 }

    before do
      settings_to_set = {
        throttle_unauthenticated_requests_per_period: requests_per_period,
        throttle_unauthenticated_enabled: true
      }
      stub_application_setting(settings_to_set)
    end

    it 'allows requests over the rate limit' do
      (1 + requests_per_period).times do
        get "/#{project.full_path}.git/info/refs", params: { service: 'git-upload-pack' }, headers: { 'Authorization' => "#{::Gitlab::Geo::BaseRequest::GITLAB_GEO_AUTH_TOKEN_TYPE} token" }
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
