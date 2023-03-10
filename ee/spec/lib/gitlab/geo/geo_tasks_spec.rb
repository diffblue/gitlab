# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::GeoTasks, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  describe '.set_primary_geo_node' do
    before do
      allow(GeoNode).to receive(:current_node_name).and_return('https://primary.geo.example.com')
      allow(GeoNode).to receive(:current_node_url).and_return('https://primary.geo.example.com')
    end

    it 'sets the primary node' do
      expect { subject.set_primary_geo_node }.to output(%r{https://primary.geo.example.com/ is now the primary Geo node}).to_stdout
    end

    it 'returns error when there is already a Primary node' do
      create(:geo_node, :primary)

      expect { subject.set_primary_geo_node }.to output(/Error saving Geo node:/).to_stdout
    end
  end

  describe '.set_secondary_as_primary' do
    let_it_be(:primary) { create(:geo_node, :primary) }

    let(:secondary) { create(:geo_node) }

    before do
      stub_current_geo_node(secondary)
      stub_current_node_name(secondary.name)
    end

    it 'aborts if the primary node is not set' do
      primary.update_column(:primary, false)

      expect(subject).to receive(:abort).with('The primary Geo site is not set').and_raise('aborted')

      expect { subject.set_secondary_as_primary }.to raise_error('aborted')
    end

    it 'aborts if current node is not identified' do
      secondary.destroy!

      expect(subject).to receive(:abort).with('Current node is not identified').and_raise('aborted')

      expect { subject.set_secondary_as_primary }.to raise_error('aborted')
    end

    it 'does nothing if run on a node that is not a secondary' do
      primary.update_column(:primary, false)
      secondary.update!(primary: true)

      expect(subject).not_to receive(:abort)

      expect { subject.set_secondary_as_primary }.to output(/#{secondary.url} is already the primary Geo site/).to_stdout
      expect(secondary.reload).to be_primary
      expect(primary.reload).to be_secondary
    end

    it 'sets the secondary as the primary node' do
      expect(subject).not_to receive(:abort)

      expect { subject.set_secondary_as_primary }.to output(/#{secondary.url} is now the primary Geo site/).to_stdout
      expect(secondary.reload).to be_primary
    end

    it 'sets the secondary as the primary node, even if the secondary is disabled' do
      secondary.update_column(:enabled, false)

      expect(subject).not_to receive(:abort)

      expect { subject.set_secondary_as_primary }.to output(/#{secondary.url} is now the primary Geo site/).to_stdout
      expect(secondary.reload).to be_primary
      expect(secondary.reload).to be_enabled
    end
  end
end
