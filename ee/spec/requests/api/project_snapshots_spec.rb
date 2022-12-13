# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectSnapshots, feature_category: :source_code_management do
  include ::EE::GeoHelpers

  let(:project) { create(:project) }

  describe 'GET /projects/:id/snapshot' do
    let(:primary) { create(:geo_node, :primary) }
    let(:secondary) { create(:geo_node) }

    before do
      stub_current_geo_node(primary)
    end

    it 'requests project repository raw archive from Geo primary as Geo secondary' do
      req = Gitlab::Geo::BaseRequest.new(scope: ::Gitlab::Geo::API_SCOPE)
      allow(req).to receive(:requesting_node) { secondary }

      get api("/projects/#{project.id}/snapshot", nil), params: {}, headers: req.headers

      expect(response).to have_gitlab_http_status(:ok)
    end
  end
end
