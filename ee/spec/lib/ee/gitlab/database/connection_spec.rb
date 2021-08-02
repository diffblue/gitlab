# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Connection do
  include ::EE::GeoHelpers

  let(:connection) { described_class.new }

  describe '#healthy?' do
    it 'returns true when replication lag is not too great' do
      allow(Postgresql::ReplicationSlot).to receive(:lag_too_great?).and_return(false)

      expect(connection.healthy?).to be_truthy
    end

    it 'returns false when replication lag is too great' do
      allow(Postgresql::ReplicationSlot).to receive(:lag_too_great?).and_return(true)

      expect(connection.healthy?).to be_falsey
    end
  end

  describe '#geo_uncached_queries' do
    context 'when no block is given' do
      it 'raises error' do
        expect do
          connection.geo_uncached_queries
        end.to raise_error('No block given')
      end
    end

    context 'when the current node is a primary' do
      let!(:primary) { create(:geo_node, :primary) }

      it 'wraps the block in an ActiveRecord::Base.uncached block' do
        stub_current_geo_node(primary)

        expect(Geo::TrackingBase).not_to receive(:uncached)
        expect(ActiveRecord::Base).to receive(:uncached).and_call_original

        expect do |b|
          connection.geo_uncached_queries(&b)
        end.to yield_control
      end
    end

    context 'when the current node is a secondary' do
      let!(:primary) { create(:geo_node, :primary) }
      let!(:secondary) { create(:geo_node) }

      it 'wraps the block in a Geo::TrackingBase.uncached block and an ActiveRecord::Base.uncached block' do
        stub_current_geo_node(secondary)

        expect(Geo::TrackingBase).to receive(:uncached).and_call_original
        expect(ActiveRecord::Base).to receive(:uncached).and_call_original

        expect do |b|
          connection.geo_uncached_queries(&b)
        end.to yield_control
      end
    end

    context 'when there is no current node' do
      it 'wraps the block in an ActiveRecord::Base.uncached block' do
        expect(Geo::TrackingBase).not_to receive(:uncached)
        expect(ActiveRecord::Base).to receive(:uncached).and_call_original

        expect do |b|
          connection.geo_uncached_queries(&b)
        end.to yield_control
      end
    end
  end
end
