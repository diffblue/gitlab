# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GeoNodeFinder, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  let_it_be(:geo_node1) { create(:geo_node) }
  let_it_be(:geo_node2) { create(:geo_node) }
  let_it_be(:geo_node3) { create(:geo_node) }

  let(:params) { {} }

  subject(:geo_nodes) { described_class.new(user, params).execute }

  describe '#execute' do
    context 'when user cannot read all Geo' do
      let_it_be(:user) { create(:user) }

      it { is_expected.to be_empty }
    end

    context 'when user can read all Geo', :enable_admin_mode do
      let_it_be(:user) { create(:user, :admin) }

      context 'filtered by ID' do
        context 'when multiple IDs are given' do
          let(:params) { { ids: [geo_node3.id, geo_node1.id] } }

          it 'returns specified Geo nodes' do
            expect(geo_nodes.to_a).to eq([geo_node1, geo_node3])
          end
        end

        context 'when a single ID is given' do
          let(:params) { { ids: [geo_node2.id] } }

          it 'returns specified Geo nodes' do
            expect(geo_nodes.to_a).to eq([geo_node2])
          end
        end

        context 'when an empty array is given' do
          let(:params) { { ids: [] } }

          it 'returns none' do
            expect(geo_nodes).to be_empty
          end
        end
      end

      context 'filtered by name' do
        context 'when multiple names are given' do
          let(:params) { { names: [geo_node3.name, geo_node1.name] } }

          it 'returns specified Geo nodes' do
            expect(geo_nodes.to_a).to eq([geo_node1, geo_node3])
          end
        end

        context 'when a single name is given' do
          let(:params) { { names: [geo_node2.name] } }

          it 'returns specified Geo nodes' do
            expect(geo_nodes.to_a).to eq([geo_node2])
          end
        end

        context 'when an empty array is given' do
          let(:params) { { names: [] } }

          it 'returns none' do
            expect(geo_nodes).to be_empty
          end
        end
      end

      context 'not filtered by ID or name' do
        it 'returns all Geo nodes' do
          expect(geo_nodes.to_a).to eq([geo_node1, geo_node2, geo_node3])
        end
      end
    end
  end
end
