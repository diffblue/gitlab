# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GeoNodes, :aggregate_failures, :request_store, :geo, :prometheus, api: true, feature_category: :geo_replication do
  include ApiHelpers
  include ::EE::GeoHelpers

  include_context 'custom session'

  let!(:admin) { create(:admin) }
  let!(:user) { create(:user) }
  let!(:primary) { create(:geo_node, :primary) }
  let!(:secondary) { create(:geo_node) }
  let!(:secondary_status) { create(:geo_node_status, :healthy, geo_node: secondary) }
  let(:unexisting_node_id) { non_existing_record_id }
  let(:group_to_sync) { create(:group) }

  describe 'POST /geo_nodes' do
    it 'denies access if not admin' do
      post api('/geo_nodes', user), params: {}
      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'returns rendering error if params are missing' do
      post api('/geo_nodes', admin, admin_mode: true), params: {}
      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'delegates the creation of the Geo node to Geo::NodeCreateService' do
      geo_node_params = {
        name: 'Test Node 1',
        url: 'http://example.com',
        selective_sync_type: "shards",
        selective_sync_shards: %w[shard1 shard2],
        selective_sync_namespace_ids: group_to_sync.id,
        minimum_reverification_interval: 10
      }
      expect_any_instance_of(Geo::NodeCreateService).to receive(:execute).once.and_call_original
      post api('/geo_nodes', admin, admin_mode: true), params: geo_node_params
      expect(response).to have_gitlab_http_status(:created)
    end
  end

  describe 'GET /geo_nodes' do
    it 'retrieves the Geo nodes if admin is logged in' do
      get api("/geo_nodes", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/geo_nodes', dir: 'ee')
    end

    it 'denies access if not admin' do
      get api('/geo_nodes', user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  describe 'GET /geo_nodes/:id' do
    it 'retrieves the Geo nodes if admin is logged in' do
      get api("/geo_nodes/#{primary.id}", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/geo_node', dir: 'ee')
      expect(json_response['web_edit_url']).to end_with("/admin/geo/sites/#{primary.id}/edit")

      links = json_response['_links']
      expect(links['self']).to end_with("/api/v4/geo_nodes/#{primary.id}")
      expect(links['status']).to end_with("/api/v4/geo_nodes/#{primary.id}/status")
      expect(links['repair']).to end_with("/api/v4/geo_nodes/#{primary.id}/repair")
    end

    it_behaves_like '404 response' do
      let(:request) { get api("/geo_nodes/#{unexisting_node_id}", admin, admin_mode: true) }
    end

    it 'denies access if not admin' do
      get api('/geo_nodes', user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  describe 'GET /geo_nodes/status' do
    it 'retrieves all Geo nodes statuses if admin is logged in' do
      create(:geo_node_status, :healthy, geo_node: primary)

      get api("/geo_nodes/status", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/geo_node_statuses', dir: 'ee')
      expect(json_response.size).to eq(2)
    end

    it 'returns only one record if only one record exists' do
      get api("/geo_nodes/status", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/geo_node_statuses', dir: 'ee')
      expect(json_response.size).to eq(1)
    end

    it 'denies access if not admin' do
      get api('/geo_nodes', user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  describe 'GET /geo_nodes/:id/status' do
    it 'retrieves the Geo nodes status if admin is logged in' do
      stub_current_geo_node(primary)
      secondary_status.update!(version: 'secondary-version', revision: 'secondary-revision')

      expect(GeoNodeStatus).not_to receive(:current_node_status)

      get api("/geo_nodes/#{secondary.id}/status", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/geo_node_status', dir: 'ee')

      expect(json_response['version']).to eq('secondary-version')
      expect(json_response['revision']).to eq('secondary-revision')

      links = json_response['_links']

      expect(links['self']).to end_with("/api/v4/geo_nodes/#{secondary.id}/status")
      expect(links['node']).to end_with("/api/v4/geo_nodes/#{secondary.id}")
    end

    it 'fetches the current node status from redis' do
      stub_current_geo_node(secondary)

      expect(GeoNodeStatus).to receive(:fast_current_node_status).and_return(secondary_status)
      expect(GeoNode).to receive(:find).and_return(secondary)

      get api("/geo_nodes/#{secondary.id}/status", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/geo_node_status', dir: 'ee')
    end

    it 'shows the database-held response if current node status exists in the database, but not redis' do
      stub_current_geo_node(secondary)

      expect(GeoNodeStatus).to receive(:fast_current_node_status).and_return(nil)
      expect(GeoNode).to receive(:find).and_return(secondary)

      get api("/geo_nodes/#{secondary.id}/status", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/geo_node_status', dir: 'ee')
    end

    it 'the secondary shows 404 response if current node status does not exist in database or redis yet' do
      stub_current_geo_node(secondary)
      secondary_status.destroy!

      expect(GeoNodeStatus).to receive(:fast_current_node_status).and_return(nil)
      expect(GeoNode).to receive(:find).and_return(secondary)

      get api("/geo_nodes/#{secondary.id}/status", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'the primary shows 404 response if secondary node status does not exist in database yet' do
      stub_current_geo_node(primary)
      secondary_status.destroy!

      expect(GeoNode).to receive(:find).and_return(secondary)

      get api("/geo_nodes/#{secondary.id}/status", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it_behaves_like '404 response' do
      let(:request) { get api("/geo_nodes/#{unexisting_node_id}/status", admin, admin_mode: true) }
    end

    it 'denies access if not admin' do
      get api("/geo_nodes/#{secondary.id}/status", user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  describe 'POST /geo_nodes/:id/repair' do
    it_behaves_like '404 response' do
      let(:request) { post api("/geo_nodes/#{unexisting_node_id}/status", admin, admin_mode: true) }
    end

    it 'denies access if not admin' do
      post api("/geo_nodes/#{secondary.id}/repair", user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'returns 200 for the primary node' do
      stub_current_geo_node(primary)
      create(:geo_node_status, :healthy, geo_node: primary)

      post api("/geo_nodes/#{primary.id}/repair", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/geo_node_status', dir: 'ee')
    end

    it 'returns 200 when node does not need repairing' do
      allow_any_instance_of(GeoNode).to receive(:missing_oauth_application?).and_return(false)

      post api("/geo_nodes/#{secondary.id}/repair", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/geo_node_status', dir: 'ee')
    end

    it 'repairs a secondary with oauth application missing' do
      allow_any_instance_of(GeoNode).to receive(:missing_oauth_application?).and_return(true)

      post api("/geo_nodes/#{secondary.id}/repair", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/geo_node_status', dir: 'ee')
    end
  end

  describe 'PUT /geo_nodes/:id' do
    it_behaves_like '404 response' do
      let(:request) { put api("/geo_nodes/#{unexisting_node_id}", admin, admin_mode: true), params: {} }
    end

    it 'denies access if not admin' do
      put api("/geo_nodes/#{secondary.id}", user), params: {}

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'updates the parameters' do
      params = {
        enabled: false,
        url: 'https://updated.example.com/',
        internal_url: 'https://internal-com.com/',
        files_max_capacity: 33,
        repos_max_capacity: 44,
        verification_max_capacity: 55,
        selective_sync_type: "shards",
        selective_sync_shards: %w[shard1 shard2],
        selective_sync_namespace_ids: [group_to_sync.id],
        minimum_reverification_interval: 10
      }.stringify_keys

      put api("/geo_nodes/#{secondary.id}", admin, admin_mode: true), params: params

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/geo_node', dir: 'ee')
      expect(json_response).to include(params)
    end

    it 'can update primary' do
      params = {
        url: 'https://updated.example.com/'
      }.stringify_keys

      put api("/geo_nodes/#{primary.id}", admin, admin_mode: true), params: params

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/geo_node', dir: 'ee')
      expect(json_response).to include(params)
    end

    it 'cannot disable a primary' do
      params = {
        enabled: false
      }.stringify_keys

      put api("/geo_nodes/#{primary.id}", admin, admin_mode: true), params: params

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    context 'auth with geo node token' do
      let(:geo_base_request) { Gitlab::Geo::BaseRequest.new(scope: ::Gitlab::Geo::API_SCOPE) }

      before do
        stub_current_geo_node(primary)
        allow(geo_base_request).to receive(:requesting_node) { secondary }
      end

      it 'enables the secondary node' do
        secondary.update!(enabled: false)

        put api("/geo_nodes/#{secondary.id}"), params: { enabled: true }, headers: geo_base_request.headers

        expect(response).to have_gitlab_http_status(:ok)
        expect(secondary.reload).to be_enabled
      end

      it 'disables the secondary node' do
        secondary.update!(enabled: true)

        put api("/geo_nodes/#{secondary.id}"), params: { enabled: false }, headers: geo_base_request.headers

        expect(response).to have_gitlab_http_status(:ok)
        expect(secondary.reload).not_to be_enabled
      end

      it 'returns bad request if you try to update the primary' do
        put api("/geo_nodes/#{primary.id}"), params: { enabled: false }, headers: geo_base_request.headers

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(primary.reload).to be_enabled
      end

      it 'responds with 401 when IP is not allowed' do
        stub_application_setting(geo_node_allowed_ips: '192.34.34.34')

        put api("/geo_nodes/#{secondary.id}"), params: {}, headers: geo_base_request.headers

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'responds 401 if auth header is bad' do
        allow_next_instance_of(Gitlab::Geo::JwtRequestDecoder) do |instance|
          allow(instance).to receive(:decode).and_raise(Gitlab::Geo::InvalidDecryptionKeyError)
        end

        put api("/geo_nodes/#{secondary.id}"), params: {}, headers: geo_base_request.headers

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /geo_nodes/:id' do
    it_behaves_like '404 response' do
      let(:request) { delete api("/geo_nodes/#{unexisting_node_id}", admin, admin_mode: true) }
    end

    it 'denies access if not admin' do
      delete api("/geo_nodes/#{secondary.id}", user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'deletes the node' do
      delete api("/geo_nodes/#{secondary.id}", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:no_content)
    end

    it 'returns 500 if Geo Node could not be deleted' do
      allow_any_instance_of(GeoNode).to receive(:destroy!).and_raise(StandardError, 'Something wrong')

      delete api("/geo_nodes/#{secondary.id}", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:internal_server_error)
    end
  end

  describe 'GET /geo_nodes/current/failures' do
    context 'primary node' do
      before do
        stub_current_geo_node(primary)
      end

      it 'forbids requests' do
        get api("/geo_nodes/current/failures", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'secondary node' do
      before do
        stub_current_geo_node(secondary)
      end

      it 'fetches the current node failures' do
        create(:geo_project_registry, :sync_failed)
        create(:geo_project_registry, :sync_failed)

        get api("/geo_nodes/current/failures", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/geo_project_registry', dir: 'ee')
      end

      it 'does not show any registry when there is no failure' do
        create(:geo_project_registry, :synced)

        get api("/geo_nodes/current/failures", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.count).to be_zero
      end

      context 'wiki type' do
        it 'only shows wiki failures' do
          create(:geo_project_registry, :wiki_sync_failed)
          create(:geo_project_registry, :repository_sync_failed)

          get api("/geo_nodes/current/failures", admin, admin_mode: true), params: { type: :wiki }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.count).to eq(1)
          expect(json_response.first['wiki_retry_count']).to be > 0
        end
      end

      context 'repository type' do
        it 'only shows repository failures' do
          create(:geo_project_registry, :wiki_sync_failed)
          create(:geo_project_registry, :repository_sync_failed)

          get api("/geo_nodes/current/failures", admin, admin_mode: true), params: { type: :repository }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.count).to eq(1)
          expect(json_response.first['repository_retry_count']).to be > 0
        end
      end

      context 'nonexistent type' do
        it 'returns a bad request' do
          create(:geo_project_registry, :repository_sync_failed)

          get api("/geo_nodes/current/failures", admin, admin_mode: true), params: { type: :nonexistent }

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      it 'denies access if not admin' do
        get api("/geo_nodes/current/failures", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      context 'verification failures' do
        before do
          stub_current_geo_node(secondary)
        end

        it 'fetches the current node checksum failures' do
          create(:geo_project_registry, :repository_verification_failed)
          create(:geo_project_registry, :wiki_verification_failed)

          get api("/geo_nodes/current/failures", admin, admin_mode: true), params: { failure_type: 'verification' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/geo_project_registry', dir: 'ee')
        end

        it 'does not show any registry when there is no failure' do
          create(:geo_project_registry, :repository_verified)

          get api("/geo_nodes/current/failures", admin, admin_mode: true), params: { failure_type: 'verification' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.count).to be_zero
        end

        context 'wiki type' do
          it 'only shows wiki verification failures' do
            create(:geo_project_registry, :repository_verification_failed)
            create(:geo_project_registry, :wiki_verification_failed)

            get api("/geo_nodes/current/failures", admin, admin_mode: true), params: { failure_type: 'verification', type: :wiki }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.count).to eq(1)
            expect(json_response.first['last_wiki_verification_failure']).to be_present
          end
        end

        context 'repository type' do
          it 'only shows repository failures' do
            create(:geo_project_registry, :repository_verification_failed)
            create(:geo_project_registry, :wiki_verification_failed)

            get api("/geo_nodes/current/failures", admin, admin_mode: true), params: { failure_type: 'verification', type: :repository }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.count).to eq(1)
            expect(json_response.first['last_repository_verification_failure']).to be_present
          end
        end
      end

      context 'checksum mismatch failures' do
        before do
          stub_current_geo_node(secondary)
        end

        it 'fetches the checksum mismatch failures from current node' do
          create(:geo_project_registry, :repository_checksum_mismatch)
          create(:geo_project_registry, :wiki_checksum_mismatch)

          get api("/geo_nodes/current/failures", admin, admin_mode: true), params: { failure_type: 'checksum_mismatch' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/geo_project_registry', dir: 'ee')
        end

        it 'does not show any registry when there is no failure' do
          create(:geo_project_registry, :repository_verified)

          get api("/geo_nodes/current/failures", admin, admin_mode: true), params: { failure_type: 'checksum_mismatch' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.count).to be_zero
        end

        context 'wiki type' do
          it 'only shows wiki checksum mismatch failures' do
            create(:geo_project_registry, :repository_checksum_mismatch)
            create(:geo_project_registry, :wiki_checksum_mismatch)

            get api("/geo_nodes/current/failures", admin, admin_mode: true), params: { failure_type: 'checksum_mismatch', type: :wiki }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.count).to eq(1)
            expect(json_response.first['wiki_checksum_mismatch']).to be_truthy
          end
        end

        context 'repository type' do
          it 'only shows repository checksum mismatch failures' do
            create(:geo_project_registry, :repository_checksum_mismatch)
            create(:geo_project_registry, :wiki_checksum_mismatch)

            get api("/geo_nodes/current/failures", admin, admin_mode: true), params: { failure_type: 'checksum_mismatch', type: :repository }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.count).to eq(1)
            expect(json_response.first['repository_checksum_mismatch']).to be_truthy
          end
        end
      end
    end
  end
end
