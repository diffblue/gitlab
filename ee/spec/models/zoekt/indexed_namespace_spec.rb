# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Zoekt::IndexedNamespace, feature_category: :global_search do
  let_it_be(:indexed_namespace1) { create(:namespace) }
  let_it_be(:indexed_namespace2) { create(:namespace) }
  let_it_be(:indexed_parent_namespace) { create(:group) }
  let_it_be(:indexed_child_namespace) { create(:group, parent: indexed_parent_namespace) }
  let_it_be(:unindexed_namespace) { create(:namespace) }
  let_it_be(:indexed_project1) { create(:project, namespace: indexed_namespace1) }
  let_it_be(:unindexed_project) { create(:project, namespace: unindexed_namespace) }
  let_it_be(:indexed_project_of_parent_namespace) { create(:project, namespace: indexed_parent_namespace) }
  let_it_be(:indexed_project_of_child_namespace) { create(:project, namespace: indexed_child_namespace) }
  let_it_be(:shard) { create(:zoekt_shard, index_base_url: 'http://example.com:1234/', search_base_url: 'http://example.com:4567/') }
  let(:search_enabled) { true }

  before do
    described_class.create!(shard: shard, namespace: indexed_namespace1, search: search_enabled)
    described_class.create!(shard: shard, namespace: indexed_namespace2, search: search_enabled)
    described_class.create!(shard: shard, namespace: indexed_parent_namespace, search: search_enabled)
  end

  context 'with validations' do
    it 'does not allow you to mark a subgroup as indexed' do
      expect do
        described_class.create!(shard: shard, namespace: indexed_child_namespace)
      end.to raise_error(/Only root namespaces can be indexed/)
    end

    it 'does not allow search to be nil' do
      np = described_class.first
      expect(np).to be_valid
      np.search = nil
      expect(np).not_to be_valid
    end
  end

  describe '#enabled_for_namespace?' do
    it 'returns true for those indexed namespace records' do
      expect(described_class.enabled_for_namespace?(indexed_namespace1)).to eq(true)
      expect(described_class.enabled_for_namespace?(indexed_namespace2)).to eq(true)
    end

    it 'returns false for unindexed namespace records' do
      expect(described_class.enabled_for_namespace?(unindexed_namespace)).to eq(false)
    end

    it 'delegates to root namespace for subgroups' do
      expect(described_class.enabled_for_namespace?(indexed_child_namespace)).to eq(true)
    end
  end

  describe '#enabled_for_project?' do
    it 'returns true for projects in indexed namespaces' do
      expect(described_class.enabled_for_project?(indexed_project1)).to eq(true)
      expect(described_class.enabled_for_project?(indexed_project_of_parent_namespace)).to eq(true)
    end

    it 'returns false for projects in unindexed namespaces' do
      expect(described_class.enabled_for_project?(unindexed_project)).to eq(false)
    end

    it 'delegates to root namespace for projects in subgroups' do
      expect(described_class.enabled_for_project?(indexed_project_of_child_namespace)).to eq(true)
    end
  end

  describe '#search_enabled_for_namespace?' do
    context 'when indexed namespace has search enabled' do
      it 'returns true for those indexed namespace records' do
        expect(described_class.search_enabled_for_namespace?(indexed_namespace1)).to eq(true)
        expect(described_class.search_enabled_for_namespace?(indexed_namespace2)).to eq(true)
      end

      it 'returns false for unindexed namespace records' do
        expect(described_class.search_enabled_for_namespace?(unindexed_namespace)).to eq(false)
      end

      it 'delegates to root namespace for subgroups' do
        expect(described_class.search_enabled_for_namespace?(indexed_child_namespace)).to eq(true)
      end
    end

    context 'when indexed namespace has search disabled' do
      let(:search_enabled) { false }

      it 'returns false even for those indexed namespace records' do
        expect(described_class.search_enabled_for_namespace?(indexed_namespace1)).to eq(false)
      end
    end
  end

  describe '#search_enabled_for_project?' do
    context 'when indexed namespace has search enabled' do
      it 'returns true for projects in indexed namespaces' do
        expect(described_class.search_enabled_for_project?(indexed_project1)).to eq(true)
        expect(described_class.search_enabled_for_project?(indexed_project_of_parent_namespace)).to eq(true)
      end

      it 'returns false for projects in unindexed namespaces' do
        expect(described_class.search_enabled_for_project?(unindexed_project)).to eq(false)
      end

      it 'delegates to root namespace for projects in subgroups' do
        expect(described_class.search_enabled_for_project?(indexed_project_of_child_namespace)).to eq(true)
      end
    end

    context 'when indexed namespace has search disabled' do
      let(:search_enabled) { false }

      it 'returns false even for projects in indexed namespaces' do
        expect(described_class.search_enabled_for_project?(indexed_project1)).to eq(false)
        expect(described_class.enabled_for_project?(indexed_project_of_parent_namespace)).to eq(true)
      end
    end
  end

  describe '#search?' do
    subject { described_class.new }

    it 'is an attribute that is enabled by default' do
      expect(subject.search).to be true
      subject.search = false
      expect(subject.search).to be false
    end
  end

  describe '#create!' do
    let(:newly_indexed_namespace) { create(:namespace) }

    it 'triggers indexing for the namespace' do
      expect(::Search::Zoekt::NamespaceIndexerWorker).to receive(:perform_async)
        .with(newly_indexed_namespace.id, :index)

      described_class.create!(shard: shard, namespace: newly_indexed_namespace)
    end
  end

  describe '#destroy!' do
    let_it_be(:newly_indexed_namespace) { create(:namespace) }
    let_it_be(:indexed_namespace_record) { described_class.create!(shard: shard, namespace: newly_indexed_namespace) }

    it 'removes index for the namespace' do
      expect(::Search::Zoekt::NamespaceIndexerWorker).to receive(:perform_async)
        .with(newly_indexed_namespace.id, :delete, shard.id)

      indexed_namespace_record.destroy!
    end
  end
end
