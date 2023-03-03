# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::NodeCreateService, feature_category: :geo_replication do
  describe '#execute' do
    it 'creates a new node with valid params' do
      service = described_class.new(name: 'foo', url: 'http://example.com')

      expect { service.execute }.to change(GeoNode, :count).by(1)
    end

    it 'does not create a node with invalid params' do
      service = described_class.new(name: 'foo', url: 'ftp://example.com')

      expect { service.execute }.not_to change(GeoNode, :count)
    end

    it 'returns true when creation succeeds' do
      service = described_class.new(name: 'foo', url: 'http://example.com')

      expect(service.execute.persisted?).to eq true
    end

    it 'returns false when creation fails' do
      service = described_class.new(name: 'foo', url: 'ftp://example.com')

      expect(service.execute.persisted?).to eq false
    end

    it 'parses the namespace_ids when node have namespace restrictions' do
      groups = create_list(:group, 2)
      params = { name: 'foo', url: 'http://example.com', namespace_ids: groups.map(&:id).join(',') }
      service = described_class.new(params)

      service.execute

      expect(GeoNode.last.namespace_ids).to match_array(groups.map(&:id))
    end
  end
end
