# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Geo::Registries::BulkUpdate, feature_category: :geo_replication do
  include GraphqlHelpers
  include EE::GeoHelpers

  let(:mutation_name) { :geo_registries_bulk_update }

  let_it_be(:current_user) { create(:user, :admin) }
  let_it_be(:primary) { create(:geo_node, :primary) }
  let_it_be(:secondary) { create(:geo_node) }

  include_context 'with geo registries shared context'

  with_them do
    let(:registry_class_argument) { registry_class.graphql_enum_key }

    def mutation_response
      graphql_mutation_response(mutation_name)
    end

    specify { expect(described_class).to require_graphql_authorizations(:read_geo_registry) }

    context 'when feature flag `geo_registries_update_mutation` is disabled' do
      before do
        stub_feature_flags(geo_registries_update_mutation: false)
      end

      let(:arguments) { { registry_class: registry_class_argument, action: 'RESYNC_ALL' } }

      let(:fields) do
        <<-FIELDS
          registryClass
          errors
        FIELDS
      end

      let(:mutation) { graphql_mutation(mutation_name, arguments, fields) }

      it_behaves_like 'a mutation that returns top-level errors',
        errors: ['`geo_registries_update_mutation` feature flag is disabled.']
    end

    context 'when geo licensed feature is not available' do
      let_it_be(:current_user) { create(:user) }

      let(:arguments) { { registry_class: registry_class_argument, action: 'RESYNC_ALL' } }

      let(:mutation) { graphql_mutation(mutation_name, arguments) }

      it_behaves_like 'a mutation that returns a top-level access error'
    end

    shared_examples 'a registries update action' do |action|
      context 'when it is valid' do
        before do
          stub_current_geo_node(secondary)
        end

        let(:arguments) { { registry_class: registry_class_argument, action: action } }

        let(:fields) do
          <<-FIELDS
            registryClass
            errors
          FIELDS
        end

        let(:mutation) { graphql_mutation(mutation_name, arguments, fields) }

        it do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(mutation_response["errors"]).to eq([])
          expect(mutation_response["registryClass"]).to include(registry_class_argument)
        end
      end

      context 'when it is invalid' do
        let(:arguments) { { registry_class: registry_class_argument, action: action } }
        let(:mutation) { graphql_mutation(mutation_name, arguments) }
        let(:error) { StandardError.new }

        before do
          allow_next_instance_of(Geo::RegistryBulkUpdateService) do |instance|
            allow(instance).to receive(action.downcase.to_sym).and_raise(error)
          end
        end

        it do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(mutation_response["errors"]).to eq(
            ["An error occurred while trying to update the registries: '#{error.message}'."]
          )

          expect(mutation_response["registryClass"]).to be_nil
        end
      end
    end

    context 'when maintenance mode is enabled' do
      before do
        stub_maintenance_mode_setting(true)
      end

      it_behaves_like 'a registries update action', 'RESYNC_ALL'
    end

    context 'with resync_all action' do
      it_behaves_like 'a registries update action', 'RESYNC_ALL'
    end

    context 'with reverify_all action' do
      it_behaves_like 'a registries update action', 'REVERIFY_ALL'
    end
  end
end
