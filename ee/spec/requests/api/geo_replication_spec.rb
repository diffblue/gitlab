# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GeoReplication, :aggregate_failures, :request_store, :geo, api: true, feature_category: :geo_replication do
  include ApiHelpers
  include ::EE::GeoHelpers

  include_context 'custom session'

  let(:primary) { create(:geo_node, :primary) }
  let(:secondary) { create(:geo_node) }
  let(:secondary_status) { create(:geo_node_status, :healthy, geo_node: secondary) }

  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

  before do
    stub_current_geo_node(secondary)
  end

  describe 'GET /geo_replication/designs' do
    it 'retrieves the designs if admin is logged in' do
      get api("/geo_replication/designs", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/geo_designs', dir: 'ee')
    end

    it 'retrieves the designs according to search term' do
      project = create(:project, name: 'bla')
      create(:design, project: project)
      create(:geo_design_registry, project: project)

      project1 = create(:project, name: 'not-what-we-search-for')
      create(:design, project: project1)
      create(:geo_design_registry, project: project1)

      get api("/geo_replication/designs", admin, admin_mode: true), params: { search: 'bla' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/geo_designs', dir: 'ee')
      expect(json_response.size).to eq(1)
      expect(json_response.first['project_id']).to eq(project.id)
    end

    it 'denies access if not admin' do
      get api('/geo_replication/designs', user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  describe 'PUT /geo_replication/designs/:id/resync' do
    it 'marks registry record for resync' do
      project = create(:project)
      create(:design, project: project)
      design_registry = create(:geo_design_registry, :synced, project: project)

      put api("/geo_replication/designs/#{project.id}/resync", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(design_registry.reload.state).to eq('pending')
    end

    it 'denies access if not admin' do
      put api('/geo_replication/designs/1/resync', user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  describe 'POST /geo_replication/designs/resync' do
    it 'marks registry record for resync' do
      create(:geo_design_registry, :synced)
      create(:geo_design_registry, :synced)

      post api("/geo_replication/designs/resync", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:created)

      ::Geo::DesignRegistry.all.each do |registry|
        expect(registry.state).to eq('pending')
      end
    end

    it 'denies access if not admin' do
      post api('/geo_replication/designs/resync', user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end
end
