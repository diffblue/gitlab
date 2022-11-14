# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Feature, stub_feature_flags: false, query_analyzers: false do
  include EE::GeoHelpers

  describe '.enable' do
    context 'when running on a Geo primary node' do
      before do
        stub_primary_node
      end

      it 'does not create a Geo::CacheInvalidationEvent if there are no Geo secondary nodes' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [] }

        expect { described_class.enable(:foo) }.not_to change(Geo::CacheInvalidationEvent, :count)
      end

      it 'creates a Geo::CacheInvalidationEvent' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [double] }

        expect { described_class.enable(:foo) }.to change(Geo::CacheInvalidationEvent, :count).by(1)
      end
    end
  end

  describe '.disable' do
    context 'when running on a Geo primary node' do
      before do
        stub_primary_node
      end

      it 'does not create a Geo::CacheInvalidationEvent if there are no Geo secondary nodes' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [] }

        expect { described_class.disable(:foo) }.not_to change(Geo::CacheInvalidationEvent, :count)
      end

      it 'creates a Geo::CacheInvalidationEvent' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [double] }

        expect { described_class.disable(:foo) }.to change(Geo::CacheInvalidationEvent, :count).by(1)
      end
    end
  end

  describe Feature::Target do
    describe '#targets' do
      context 'when repository target works with group wiki' do
        let_it_be(:group) { create(:group) }

        subject do
          described_class.new(repository: group.wiki.repository.full_path)
        end

        it 'returns all found targets' do
          expect(subject.targets).to be_an(Array)
          expect(subject.targets).to eq([group.wiki.repository])
        end
      end
    end
  end
end
