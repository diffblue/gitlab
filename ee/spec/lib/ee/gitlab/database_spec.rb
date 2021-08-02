# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database do
  include ::EE::GeoHelpers

  describe '.read_only?' do
    context 'with Geo enabled' do
      before do
        allow(Gitlab::Geo).to receive(:enabled?) { true }
        allow(Gitlab::Geo).to receive(:current_node) { geo_node }
      end

      context 'is Geo secondary node' do
        let(:geo_node) { create(:geo_node) }

        it 'returns true' do
          expect(described_class.read_only?).to be_truthy
        end
      end

      context 'is Geo primary node' do
        let(:geo_node) { create(:geo_node, :primary) }

        it 'returns false when is Geo primary node' do
          expect(described_class.read_only?).to be_falsey
        end
      end
    end

    context 'with Geo disabled' do
      it 'returns false' do
        expect(described_class.read_only?).to be_falsey
      end
    end

    context 'in maintenance mode' do
      before do
        stub_maintenance_mode_setting(true)
      end

      it 'returns true' do
        expect(described_class.read_only?).to be_truthy
      end
    end
  end
end
