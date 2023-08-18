# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::Zoekt::ProjectTransferWorker, feature_category: :global_search do
  let_it_be(:namespace) { create(:group) }
  let_it_be(:old_namespace) { create(:group) }
  # create project in indexed_namespace to emulate the successful project transfer
  # which would have occurred prior to this worker being invoked
  let_it_be(:project) { create(:project, namespace: namespace) }

  subject(:worker) { described_class.new }

  include_examples 'an idempotent worker' do
    let(:job_args) { [project.id, namespace.id] }

    describe '#perform' do
      context 'when zoekt is enabled' do
        before do
          stub_feature_flags(index_code_with_zoekt: true)
          allow(::Zoekt::IndexedNamespace).to receive(:enabled_for_namespace?).with(old_namespace).and_return(
            namespace_zoekt_enabled)
          allow(::Zoekt::IndexedNamespace).to receive(:enabled_for_project?).with(project).and_return(
            project_zoekt_enabled)
        end

        context 'when moving the project from a non-indexed namespace to an indexed namespace' do
          let(:namespace_zoekt_enabled) { false }
          let(:project_zoekt_enabled) { true }

          it 'schedules the project to be indexed and does not delete the project' do
            expect(Search::Zoekt::DeleteProjectWorker).not_to receive(:perform_async)
            expect(::Zoekt::IndexerWorker).to receive(:perform_async).with(project.id).once
            worker.perform(project.id, old_namespace.id)
          end
        end

        context 'when moving the project from an indexed namespace to a non-indexed namespace' do
          let(:namespace_zoekt_enabled) { true }
          let(:project_zoekt_enabled) { false }

          it 'schedules the project to be deleted and does not index anything' do
            expect(Search::Zoekt::DeleteProjectWorker).to receive(:perform_async).with(old_namespace.id,
              project.id).once
            expect(::Zoekt::IndexerWorker).not_to receive(:perform_async)
            worker.perform(project.id, old_namespace.id)
          end
        end
      end

      context 'when zoekt is disabled' do
        before do
          stub_feature_flags(index_code_with_zoekt: false)
        end

        it 'does nothing' do
          expect(Search::Zoekt::DeleteProjectWorker).not_to receive(:perform_async)
          expect(::Zoekt::IndexerWorker).not_to receive(:perform_async)
          worker.perform(project.id, old_namespace.id)
        end
      end
    end
  end
end
