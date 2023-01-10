# frozen_string_literal: true

RSpec.shared_examples 'gets registries for' do |args|
  let(:field_name) { args[:field_name] }
  let(:registry_class_name) { args[:registry_class_name] }
  let(:registry_factory) { args[:registry_factory] }
  let(:registry_foreign_key_field_name) { args[:registry_foreign_key_field_name] }
  let(:replicator_class) { Geo.const_get(registry_class_name, false).replicator_class }
  let(:feature_flag) { replicator_class.replication_enabled_feature_key }
  let(:verification_enabled) { replicator_class.verification_enabled? }
  let(:registry_foreign_key) { registry_foreign_key_field_name.underscore }
  let(:field_name_sym) { field_name.underscore.to_sym }

  include GraphqlHelpers
  include EE::GeoHelpers

  let_it_be(:secondary) { create(:geo_node) }
  let!(:registry1) { create(registry_factory) } # rubocop:disable Rails/SaveBang
  let!(:registry2) { create(registry_factory) } # rubocop:disable Rails/SaveBang

  let(:query) do
    excluded = verification_enabled ? [] : %w[verifiedAt verificationRetryAt]

    <<~QUERY
      {
        geoNode {
          #{field_name} {
            nodes {
              #{all_graphql_fields_for(registry_class_name, excluded: excluded)}
            }
          }
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

  it 'returns registries' do
    expected = [registry1, registry2].map do |registry|
      registry_to_graphql_data_hash(registry)
    end

    post_graphql(query, current_user: current_user)

    actual = graphql_data_at(:geo_node, field_name_sym, :nodes)
    expect(actual).to eq(expected)
  end

  context 'when paginating' do
    let!(:expected_registry1) { create(registry_factory) } # rubocop:disable Rails/SaveBang
    let!(:expected_registry2) { create(registry_factory) } # rubocop:disable Rails/SaveBang

    def query(registries_params)
      <<~QUERY
        {
          geoNode {
            #{field_name}(#{registries_params}) {
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
    end

    it 'supports cursor-based pagination' do
      post_graphql(query('first: 2'), current_user: current_user)

      edges = graphql_data_at(:geo_node, field_name_sym, :edges)
      page_info = graphql_data_at(:geo_node, field_name_sym, :page_info)
      has_next_page = graphql_data_at(:geo_node, field_name_sym, :page_info, :has_next_page)

      expect(edges.size).to eq(2)
      expect(page_info).to be_present
      expect(has_next_page).to eq(true)
    end

    it 'returns the correct page of registries' do
      # Get first page
      post_graphql(query('first: 2'), current_user: current_user)
      end_cursor = graphql_data_at(:geo_node, field_name_sym, :page_info, :end_cursor)

      # Get second page
      post_graphql(query("first: 2, after: \"#{end_cursor}\""), current_user: current_user)

      response_data = Gitlab::Json.parse(response.body).dig('data', 'geoNode', GraphqlHelpers.fieldnamerize(field_name), 'edges')
      first_result = response_data.first['node']
      second_result = response_data.second['node']

      expect(first_result).to eq('id' => expected_registry1.to_global_id.to_s)
      expect(second_result).to eq('id' => expected_registry2.to_global_id.to_s)
    end
  end

  def registry_to_graphql_data_hash(registry)
    hash = {
      'id' => registry.to_global_id.to_s,
      registry_foreign_key_field_name => registry.send(registry_foreign_key).to_s,
      'state' => registry.state_name.to_s.upcase,
      'retryCount' => registry.retry_count,
      'lastSyncFailure' => registry.last_sync_failure,
      'retryAt' => registry.retry_at,
      'lastSyncedAt' => registry.last_synced_at,
      'createdAt' => registry.created_at.iso8601
    }

    hash['verifiedAt'] = registry.verified_at if verification_enabled
    hash['verificationRetryAt'] = registry.verification_retry_at if verification_enabled

    hash
  end
end
