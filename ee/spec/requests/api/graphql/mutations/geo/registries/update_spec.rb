# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Geo::Registries::Update, feature_category: :geo_replication do
  include GraphqlHelpers
  include EE::GeoHelpers

  let_it_be(:current_user) { create(:user, :admin) }
  let_it_be(:registry) { create(:geo_snippet_repository_registry) }
  let_it_be(:registry_class) { 'SNIPPET_REPOSITORY_REGISTRY' }
  let_it_be(:registry_global_id) { registry.to_global_id.to_s }
  let_it_be(:mutation_name) { :geo_registries_update }
  let_it_be(:primary) { create(:geo_node, :primary) }
  let_it_be(:secondary) { create(:geo_node) }

  let(:expected_keys) do
    %w[
      id
      state
      retryCount
      lastSyncFailure
      retryAt
      lastSyncedAt
      verifiedAt
      verificationRetryAt
      createdAt
      snippetRepositoryId
    ]
  end

  specify { expect(described_class).to require_graphql_authorizations(:read_geo_registry) }

  def mutation_response
    graphql_mutation_response(mutation_name)
  end

  context 'when feature flag `geo_registries_update_mutation` is disabled' do
    let(:arguments) { { registry_class: registry_class, registry_id: registry_global_id, action: 'RESYNC' } }

    let(:fields) do
      <<-FIELDS
        registry {
          #{query_graphql_fragment('SnippetRepositoryRegistry')}
        }
        errors
      FIELDS
    end

    let(:mutation) { graphql_mutation(mutation_name, arguments, fields) }

    before do
      stub_feature_flags(geo_registries_update_mutation: false)
    end

    it_behaves_like 'a mutation that returns top-level errors',
      errors: ['`geo_registries_update_mutation` feature flag is disabled.']
  end

  context 'when geo licensed feature is not available' do
    let_it_be(:current_user) { create(:user) }

    let(:arguments) do
      {
        registry_class: registry_class,
        registry_id: registry_global_id,
        action: 'RESYNC'
      }
    end

    let(:mutation) { graphql_mutation(mutation_name, arguments) }

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when instance is read_only' do
    let(:arguments) do
      {
        registry_class: registry_class,
        registry_id: registry_global_id,
        action: 'RESYNC'
      }
    end

    let(:mutation) { graphql_mutation(mutation_name, arguments) }

    before do
      stub_maintenance_mode_setting(true)
    end

    it 'returns an error' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response).to be_nil
      expect(fresh_response_data.dig("errors", 0, "message"))
        .to eq("You cannot perform write operations on a read-only instance")
    end
  end

  shared_examples 'a valid registry update' do
    let(:arguments) { { registry_class: registry_class, registry_id: registry_global_id, action: action } }

    let(:fields) do
      <<-FIELDS
        registry {
          #{query_graphql_fragment('SnippetRepositoryRegistry')}
        }
        errors
      FIELDS
    end

    let(:mutation) { graphql_mutation(mutation_name, arguments, fields) }

    before do
      stub_current_geo_node(secondary)
    end

    it do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response["errors"]).to eq([])
      expect(mutation_response["registry"]).to include(*expected_keys)
    end
  end

  shared_examples 'an invalid registry update' do
    let(:arguments) { { registry_class: registry_class, registry_id: registry_global_id, action: action } }
    let(:mutation) { graphql_mutation(mutation_name, arguments) }
    let(:error) { StandardError.new }

    before do
      allow_next_instance_of(Geo::RegistryUpdateService) do |instance|
        allow(instance).to receive(action.downcase.to_sym).and_raise(error)
      end
    end

    it do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response["errors"]).to eq([error.message])
      expect(mutation_response["registry"]).to be_nil
    end
  end

  context 'when geo site is secondary' do
    let(:action) { 'RESYNC' }

    it_behaves_like 'a valid registry update'
  end

  context 'when updating a single registry' do
    before do
      stub_current_geo_node(secondary)
    end

    context 'with resync action' do
      let(:action) { 'RESYNC' }

      it_behaves_like 'a valid registry update'
      it_behaves_like 'an invalid registry update'
    end

    context 'with reverify action' do
      let(:action) { 'REVERIFY' }

      it_behaves_like 'a valid registry update'
      it_behaves_like 'an invalid registry update'
    end
  end
end
