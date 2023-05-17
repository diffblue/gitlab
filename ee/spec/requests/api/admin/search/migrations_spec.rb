# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Admin::Search::Migrations, :elastic, feature_category: :global_search do
  let_it_be(:admin) { create(:admin) }

  before do
    stub_ee_application_setting(elasticsearch_indexing: true)
  end

  shared_examples 'an API that returns 400 when elasticsearch_indexing is disabled' do |verb|
    before do
      stub_ee_application_setting(elasticsearch_indexing: false)
    end

    it 'returns bad_request status' do
      send(verb, api(path, admin, admin_mode: true))

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']).to match(/indexing is not enabled/)
    end
  end

  shared_examples 'an API that returns 404 for missing ids' do |verb|
    it 'returns not_found status' do
      send(verb, api(path, admin, admin_mode: true))

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'an API that returns 401 for unauthenticated requests' do |verb|
    it 'returns not_found status' do
      send(verb, api(path, nil))

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  describe 'GET /admin/search/migrations' do
    let(:path) { '/admin/search/migrations' }

    it_behaves_like 'GET request permissions for admin mode'
    it_behaves_like 'an API that returns 401 for unauthenticated requests', :get
    it_behaves_like 'an API that returns 400 when elasticsearch_indexing is disabled', :get

    it 'lists all migrations' do
      get api(path, admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.count).to eq(Elastic::DataMigrationService.migrations.count)
      expect(json_response.first['version']).to eq(20201105181100)
    end
  end

  describe 'GET /admin/search/migrations/:migration_id' do
    let(:migration_id) { 20230426195404 }
    let(:path) { "/admin/search/migrations/#{migration_id}" }

    it_behaves_like 'GET request permissions for admin mode'
    it_behaves_like 'an API that returns 401 for unauthenticated requests', :get
    it_behaves_like 'an API that returns 400 when elasticsearch_indexing is disabled', :get

    shared_examples 'an API that returns a migration' do
      it 'returns a migration', :aggregate_failures do
        get api(path, admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to match(hash_including('version' => 20230426195404,
          'name' => 'AddHiddenToMergeRequests'))
      end
    end

    context 'when requested by version' do
      let(:migration_id) { 20230426195404 }

      it_behaves_like 'an API that returns a migration'
    end

    context 'when requested by name' do
      let(:migration_id) { 'AddHiddenToMergeRequests' }

      it_behaves_like 'an API that returns a migration'
    end
  end
end
