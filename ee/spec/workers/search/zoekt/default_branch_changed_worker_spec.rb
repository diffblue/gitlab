# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::Zoekt::DefaultBranchChangedWorker, feature_category: :global_search do
  let_it_be(:zoekt_indexed_namespace) { create(:zoekt_indexed_namespace) }
  let_it_be(:project) { create(:project, :repository, namespace: zoekt_indexed_namespace.namespace) }

  let(:default_branch_changed_event) { Repositories::DefaultBranchChangedEvent.new(data: data) }
  let(:container) { project }
  let(:data) { { container_id: container.id, container_type: container.class.name } }

  before do
    allow(::Zoekt::IndexerWorker).to receive(:perform_async).and_return(true)
  end

  it_behaves_like 'subscribes to event' do
    let(:event) { default_branch_changed_event }
  end

  context 'when project uses zoekt' do
    it 'schedules ::Zoekt::IndexerWorker' do
      expect(::Zoekt::IndexerWorker).to receive(:perform_async).with(project.id)

      consume_event(subscriber: described_class, event: default_branch_changed_event)
    end
  end

  context 'when project does not exist' do
    let(:data) { { container_id: non_existing_record_id, container_type: container.class.name } }

    it 'does not schedule ::Zoekt::IndexerWorker and does not raise an exception' do
      expect(::Zoekt::IndexerWorker).not_to receive(:perform_async)

      expect { consume_event(subscriber: described_class, event: default_branch_changed_event) }
        .not_to raise_exception
    end
  end

  context 'when project does not use zoekt' do
    let(:project_double) { instance_double(Project, use_zoekt?: false) }

    before do
      allow(Project).to receive(:find_by_id).and_return(project_double)
    end

    it 'does not schedule ::Zoekt::IndexerWorker' do
      expect(::Zoekt::IndexerWorker).not_to receive(:perform_async)

      consume_event(subscriber: described_class, event: default_branch_changed_event)
    end
  end

  context 'when feature flag index_code_with_zoekt is disabled' do
    before do
      stub_feature_flags(index_code_with_zoekt: false)
    end

    it 'does not schedule ::Zoekt::IndexerWorker' do
      expect(::Zoekt::IndexerWorker).not_to receive(:perform_async)

      consume_event(subscriber: described_class, event: default_branch_changed_event)
    end
  end

  context 'when zoekt_code_search license feature is not available' do
    before do
      stub_licensed_features(zoekt_code_search: false)
    end

    it 'does not schedule ::Zoekt::IndexerWorker' do
      expect(::Zoekt::IndexerWorker).not_to receive(:perform_async)

      consume_event(subscriber: described_class, event: default_branch_changed_event)
    end
  end

  context 'when passed a non-Project class' do
    let(:container) { instance_double(Group, id: 1) }

    it 'does not schedule ::Zoekt::IndexerWorker' do
      expect(::Zoekt::IndexerWorker).not_to receive(:perform_async)

      consume_event(subscriber: described_class, event: default_branch_changed_event)
    end
  end
end
