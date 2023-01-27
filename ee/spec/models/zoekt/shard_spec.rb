# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Zoekt::Shard, feature_category: :global_search do
  let_it_be(:indexed_namespace1) { create(:namespace) }
  let_it_be(:indexed_namespace2) { create(:namespace) }
  let_it_be(:unindexed_namespace) { create(:namespace) }
  let(:shard) { described_class.create!(index_base_url: 'http://example.com:1234/', search_base_url: 'http://example.com:4567/') }

  before do
    Zoekt::IndexedNamespace.create!(shard: shard, namespace: indexed_namespace1)
    Zoekt::IndexedNamespace.create!(shard: shard, namespace: indexed_namespace2)
  end

  it 'has many indexed_namespaces' do
    expect(shard.indexed_namespaces.count).to eq(2)
    expect(shard.indexed_namespaces.map(&:namespace)).to contain_exactly(indexed_namespace1, indexed_namespace2)
  end
end
