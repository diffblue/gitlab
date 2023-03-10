# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Geo::GeoNodeResolver, feature_category: :geo_replication do
  include GraphqlHelpers
  include EE::GeoHelpers

  describe '#resolve' do
    let_it_be(:primary) { create(:geo_node, :primary) }
    let_it_be(:secondary) { create(:geo_node) }
    let_it_be(:user) { create(:user, :admin) }

    let(:gql_context) { { current_user: user } }

    context 'when the user has permission to view Geo data', :enable_admin_mode do
      context 'with a name' do
        context 'when the given name matches a node' do
          it 'returns the GeoNode' do
            expect(resolve_geo_node(name: primary.name)).to eq(primary)
            expect(resolve_geo_node(name: secondary.name)).to eq(secondary)
          end
        end

        context 'when the given name does not match any node' do
          it 'returns nil' do
            expect(resolve_geo_node(name: 'a node by this name does not exist')).to be_nil
          end
        end
      end

      context 'without a name' do
        context 'when the GitLab instance has a current Geo node' do
          before do
            stub_current_geo_node(secondary)
            stub_current_node_name(secondary.name)
          end

          it 'returns the GeoNode' do
            expect(resolve_geo_node).to eq(secondary)
          end
        end

        context 'when the GitLab instance does not have a current Geo node' do
          it 'returns nil' do
            expect(resolve_geo_node).to be_nil
          end
        end
      end
    end

    context 'when the user does not have permission to view Geo data' do
      it 'returns nil' do
        expect(resolve_geo_node).to be_nil
      end
    end
  end

  def resolve_geo_node(args = {})
    resolve(described_class, obj: nil, args: args, ctx: gql_context)
  end
end
