# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::IndexRegistry, feature_category: :global_search do
  describe '.index_for_namespace' do
    let(:index) { build(:search_index, type: type) }
    let(:type) { Search::NoteIndex }
    let(:namespace) { create(:namespace) }
    let(:cache_backend) { Gitlab::ProcessMemoryCache.cache_backend }

    context 'when an index is already assigned to a namespace' do
      let!(:assignment) { Search::NamespaceIndexAssignment.assign_index(namespace: namespace, index: assigned_index) }
      let(:assigned_index) { create(:search_index, type: type, path: 'assigned-index-path') }

      it 'returns the index in the index assignment' do
        expect(described_class.index_for_namespace(namespace: namespace, type: type)).to eq(assigned_index)
      end
    end

    context 'when there is not an index assignment' do
      let(:index) { create(:search_index, type: type) }

      it 'makes a new assignment and returns routed index for a namespace' do
        expect(type).to receive(:route).with(hash: namespace.hashed_root_namespace_id).and_return(index)
        expect(::Search::NamespaceIndexAssignment).to receive(:assign_index).with(namespace: namespace, index: index)
        expect(described_class.index_for_namespace(namespace: namespace, type: type)).to eq(index)
      end
    end

    it 'uses cache correctly' do
      expect(cache_backend).to receive(:fetch).with(
        [described_class.name, :index_for_namespace, namespace.id, type.name],
        expires_in: 1.minute
      ).and_call_original

      described_class.index_for_namespace(namespace: namespace, type: type)
    end

    it 'assigns the index when there is a cache miss' do
      expect(type).to receive(:route).with(hash: namespace.hashed_root_namespace_id).and_return(index)
      expect(Search::NamespaceIndexAssignment).to receive(:assign_index).with(namespace: namespace, index: index).once
      described_class.index_for_namespace(namespace: namespace, type: type)

      expect(Search::NamespaceIndexAssignment).not_to receive(:assign_index)

      5.times do
        described_class.index_for_namespace(namespace: namespace, type: type)
      end
    end
  end
end
