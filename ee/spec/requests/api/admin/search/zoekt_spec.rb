# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Admin::Search::Zoekt, :zoekt, feature_category: :global_search do
  let(:admin) { create(:admin) }
  let_it_be(:namespace) { create(:group) }
  let_it_be(:unindexed_namespace) { create(:group) }
  let_it_be(:project) { create(:project) }
  let(:project_id) { project.id }
  let(:namespace_id) { namespace.id }
  let(:params) { {} }
  let(:shard) { ::Zoekt::Shard.first }
  let(:shard_id) { shard.id }

  shared_examples 'an API that returns 400 when the index_code_with_zoekt feature flag is disabled' do |verb|
    before do
      stub_feature_flags(index_code_with_zoekt: false)
    end

    it 'returns not_found status' do
      send(verb, api(path, admin, admin_mode: true))

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('index_code_with_zoekt feature flag is not enabled')
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

  describe 'PUT /admin/zoekt/projects/:projects/index' do
    let(:path) { "/admin/zoekt/projects/#{project_id}/index" }

    it_behaves_like "PUT request permissions for admin mode"
    it_behaves_like "an API that returns 401 for unauthenticated requests", :put
    it_behaves_like "an API that returns 400 when the index_code_with_zoekt feature flag is disabled", :put

    it 'triggers indexing for the project' do
      expect(::Zoekt::IndexerWorker).to receive(:perform_async).with(project.id).and_return('the-job-id')

      put api(path, admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['job_id']).to eq('the-job-id')
    end

    it_behaves_like 'an API that returns 404 for missing ids', :put do
      let(:project_id) { Project.maximum(:id) + 100 }
    end
  end

  describe 'GET /admin/zoekt/shards' do
    let(:path) { '/admin/zoekt/shards' }
    let!(:another_shard) { ::Zoekt::Shard.create!(index_base_url: 'http://111.111.111.111/', search_base_url: 'http://111.111.111.112/') }

    it_behaves_like "GET request permissions for admin mode"
    it_behaves_like "an API that returns 401 for unauthenticated requests", :get

    it 'returns all shards' do
      get api(path, admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to match_array([
        hash_including(
          'id' => shard.id,
          'index_base_url' => shard.index_base_url,
          'search_base_url' => shard.search_base_url
        ),
        hash_including(
          'id' => another_shard.id,
          'index_base_url' => 'http://111.111.111.111/',
          'search_base_url' => 'http://111.111.111.112/'
        )
      ])
    end
  end

  describe 'GET /admin/zoekt/shards/:shard_id/indexed_namespaces' do
    let(:path) { "/admin/zoekt/shards/#{shard_id}/indexed_namespaces" }

    let!(:indexed_namespace) { ::Zoekt::IndexedNamespace.create!(shard: shard, namespace: namespace) }
    let!(:another_indexed_namespace) { ::Zoekt::IndexedNamespace.create!(shard: shard, namespace: create(:namespace)) }

    let!(:another_shard) { ::Zoekt::Shard.create!(index_base_url: 'http://111.111.111.198/', search_base_url: 'http://111.111.111.199/') }
    let!(:indexed_namespace_for_another_shard) do
      ::Zoekt::IndexedNamespace.create!(shard: another_shard, namespace: create(:namespace))
    end

    it_behaves_like "GET request permissions for admin mode"
    it_behaves_like "an API that returns 401 for unauthenticated requests", :get

    it 'returns all indexed namespaces for this shard' do
      get api(path, admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to match_array([
        hash_including(
          'id' => indexed_namespace.id,
          'zoekt_shard_id' => shard.id,
          'namespace_id' => namespace.id
        ),
        hash_including(
          'id' => another_indexed_namespace.id,
          'zoekt_shard_id' => shard.id,
          'namespace_id' => another_indexed_namespace.namespace_id
        )
      ])
    end

    it 'returns at most MAX_RESULTS most recent rows' do
      stub_const("#{described_class}::MAX_RESULTS", 1)

      get api(path, admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to match_array([
        hash_including(
          'id' => another_indexed_namespace.id,
          'zoekt_shard_id' => shard.id,
          'namespace_id' => another_indexed_namespace.namespace_id
        )
      ])
    end

    it_behaves_like 'an API that returns 404 for missing ids', :get do
      let(:shard_id) { ::Zoekt::Shard.maximum(:id) + 100 }
    end
  end

  describe 'PUT /admin/zoekt/shards/:shard_id/indexed_namespaces/:namespace_id' do
    let(:path) { "/admin/zoekt/shards/#{shard_id}/indexed_namespaces/#{namespace_id}" }

    it_behaves_like "PUT request permissions for admin mode"
    it_behaves_like "an API that returns 401 for unauthenticated requests", :put
    it_behaves_like "an API that returns 400 when the index_code_with_zoekt feature flag is disabled", :put

    it 'creates a Zoekt::IndexedNamespace for this shard and namespace pair' do
      expect do
        put api(path, admin, admin_mode: true)
      end.to change { ::Zoekt::IndexedNamespace.count }.from(0).to(1)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['id']).to eq(::Zoekt::IndexedNamespace.find_by(shard: shard, namespace: namespace).id)
    end

    context 'when it already exists' do
      it 'returns the existing one' do
        id = ::Zoekt::IndexedNamespace.create!(shard: shard, namespace: namespace).id

        put api(path, admin, admin_mode: true)

        expect(json_response['id']).to eq(id)
      end
    end

    context 'with missing shard_id' do
      it_behaves_like 'an API that returns 404 for missing ids', :put do
        let(:shard_id) { ::Zoekt::Shard.maximum(:id) + 100 }
      end
    end

    context 'with missing namespace_id' do
      it_behaves_like 'an API that returns 404 for missing ids', :put do
        let(:namespace_id) { ::Namespace.maximum(:id) + 100 }
      end
    end
  end

  describe 'DELETE /admin/zoekt/shards/:shard_id/indexed_namespaces/:namespace_id' do
    let(:path) { "/admin/zoekt/shards/#{shard_id}/indexed_namespaces/#{namespace_id}" }

    before do
      ::Zoekt::IndexedNamespace.create!(shard: shard, namespace: namespace)
    end

    it_behaves_like "DELETE request permissions for admin mode"
    it_behaves_like "an API that returns 401 for unauthenticated requests", :delete

    it 'removes the Zoekt::IndexedNamespace for this shard and namespace pair' do
      expect do
        delete api(path, admin, admin_mode: true)
      end.to change { ::Zoekt::IndexedNamespace.count }.from(1).to(0)

      expect(response).to have_gitlab_http_status(:no_content)
    end

    context 'with missing shard_id' do
      it_behaves_like 'an API that returns 404 for missing ids', :delete do
        let(:shard_id) { ::Zoekt::Shard.maximum(:id) + 100 }
      end
    end

    context 'with missing namespace_id' do
      it_behaves_like 'an API that returns 404 for missing ids', :delete do
        let(:namespace_id) { ::Namespace.maximum(:id) + 100 }
      end
    end
  end
end
