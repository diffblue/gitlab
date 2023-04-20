# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::Zoekt::NamespaceIndexerWorker, :zoekt, feature_category: :global_search do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:unindexed_namespace) { create(:namespace) }
  let_it_be(:unindexed_project) { create(:project, namespace: unindexed_namespace) }

  before do
    zoekt_ensure_namespace_indexed!(namespace)
  end

  describe '#perform' do
    subject { described_class.new.perform(namespace.id, 'index') }

    let_it_be(:projects) { create_list :project, 3, namespace: namespace }

    it 'indexes all projects belonging to the namespace' do
      expect(Zoekt::IndexerWorker).to receive(:bulk_perform_async).with(a_collection_containing_exactly(
        [projects[0].id],
        [projects[1].id],
        [projects[2].id]
      ))

      subject
    end

    context 'when zoekt indexing is disabled' do
      before do
        stub_feature_flags(index_code_with_zoekt: false)
      end

      it 'does nothing' do
        expect(::Zoekt::IndexerWorker).not_to receive(:bulk_perform_async)

        subject
      end
    end

    context 'when zoekt indexing is not enabled for the namespace' do
      subject { described_class.new.perform(unindexed_namespace.id, 'index') }

      it 'does nothing' do
        expect(::Zoekt::IndexerWorker).not_to receive(:bulk_perform_async)

        subject
      end
    end
  end
end
