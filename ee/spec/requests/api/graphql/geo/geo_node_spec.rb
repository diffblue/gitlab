# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Getting the current Geo node', feature_category: :geo_replication do
  include GraphqlHelpers
  include EE::GeoHelpers

  let_it_be(:secondary) { create(:geo_node) }

  let(:query) do
    <<~QUERY
      {
        geoNode {
          id
          primary
          enabled
          name
          url
          internalUrl
          filesMaxCapacity
          reposMaxCapacity
          verificationMaxCapacity
          containerRepositoriesMaxCapacity
          syncObjectStorage
          selectiveSyncType
          selectiveSyncShards
          minimumReverificationInterval
        }
      }
    QUERY
  end

  let(:current_user) { create(:user, :admin) }

  before do
    stub_current_geo_node(secondary)
    stub_current_node_name(secondary.name)
  end

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql(query, current_user: current_user)
    end
  end

  it 'returns the current GeoNode' do
    expected = {
      'id' => secondary.to_global_id.to_s,
      'primary' => secondary.primary,
      'enabled' => secondary.enabled,
      'name' => secondary.name,
      'url' => secondary.url,
      'internalUrl' => secondary.internal_url,
      'filesMaxCapacity' => secondary.files_max_capacity,
      'reposMaxCapacity' => secondary.repos_max_capacity,
      'verificationMaxCapacity' => secondary.verification_max_capacity,
      'containerRepositoriesMaxCapacity' => secondary.container_repositories_max_capacity,
      'syncObjectStorage' => secondary.sync_object_storage,
      'selectiveSyncType' => secondary.selective_sync_type,
      'selectiveSyncShards' => secondary.selective_sync_shards,
      'minimumReverificationInterval' => secondary.minimum_reverification_interval
    }

    post_graphql(query, current_user: current_user)

    expect(graphql_data_at(:geo_node)).to eq(expected)
  end

  context 'connection fields' do
    context 'when selectiveSyncNamespaces is queried' do
      let_it_be(:namespace_link) { create(:geo_node_namespace_link, geo_node: secondary) }

      it 'returns selective sync namespaces' do
        query =
          <<~QUERY
            {
              geoNode {
                selectiveSyncNamespaces {
                  nodes {
                    id
                    name
                  }
                }
              }
            }
          QUERY

        expected = [
          {
            'id' => secondary.namespaces.last.to_global_id.to_s,
            'name' => secondary.namespaces.last.name
          }
        ]

        post_graphql(query, current_user: current_user)

        actual = graphql_data_at(:geo_node, :selective_sync_namespaces, :nodes)
        expect(actual).to eq(expected)
      end

      it 'supports cursor-based pagination' do
        create(:geo_node_namespace_link, geo_node: secondary)
        create(:geo_node_namespace_link, geo_node: secondary)

        query =
          <<~QUERY
            {
              geoNode {
                selectiveSyncNamespaces(first: 2) {
                  edges {
                    node {
                      id
                    }
                    cursor
                  }
                  pageInfo {
                    endCursor
                    hasNextPage
                  }
                }
              }
            }
          QUERY

        post_graphql(query, current_user: current_user)

        edges = graphql_data_at(:geo_node, :selective_sync_namespaces, :edges)
        page_info = graphql_data_at(:geo_node, :selective_sync_namespaces, :page_info)

        expect(edges.size).to eq(2)
        expect(page_info).to be_present
      end
    end
  end
end
