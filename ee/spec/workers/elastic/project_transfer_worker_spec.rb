# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::ProjectTransferWorker, :elastic, feature_category: :global_search do
  let_it_be(:non_indexed_namespace) { create(:group) }
  let_it_be(:indexed_namespace) { create(:group) }
  # create project in indexed_namespace to emulate the successful project transfer
  # which would have occurred prior to this worker being invoked
  let_it_be(:project) { create(:project, namespace: indexed_namespace) }

  subject(:worker) { described_class.new }

  before do
    stub_ee_application_setting(elasticsearch_indexing: true)
  end

  include_examples 'an idempotent worker' do
    let(:job_args) { [project.id, non_indexed_namespace.id, indexed_namespace.id] }

    describe '#perform' do
      context 'when elasticsearch_limit_indexing is on' do
        before do
          stub_ee_application_setting(elasticsearch_limit_indexing: true)
        end

        context 'when transferring from a non-existent namespace to an indexed namespace' do
          before do
            create(:elasticsearch_indexed_namespace, namespace: indexed_namespace)
          end

          it 'invalidates cache when an namespace is not found' do
            expect(ElasticDeleteProjectWorker).not_to receive(:perform_async)
            expect(Elastic::ProcessInitialBookkeepingService).to receive(:backfill_projects!).with(project)
            expect(::Gitlab::CurrentSettings)
              .to receive(:invalidate_elasticsearch_indexes_cache_for_project!)
              .with(project.id).and_call_original

            worker.perform(project.id, "non-existent-namespace-id", indexed_namespace.id)
          end
        end

        context 'when transferring from a non-indexed namespace to an indexed namespace' do
          before do
            create(:elasticsearch_indexed_namespace, namespace: indexed_namespace)
          end

          it 'invalidates the cache and indexes the project and all associated data' do
            expect(ElasticDeleteProjectWorker).not_to receive(:perform_async)
            expect(Elastic::ProcessInitialBookkeepingService).to receive(:backfill_projects!).with(project)
            expect(::Gitlab::CurrentSettings)
              .to receive(:invalidate_elasticsearch_indexes_cache_for_project!)
              .with(project.id).and_call_original

            worker.perform(project.id, non_indexed_namespace.id, indexed_namespace.id)
          end
        end

        context 'when transferring between an indexed namespace to a non-indexed namespace' do
          # create project in non_indexed_namespace to emulate the successful project transfer to the
          # non-indexed namespace which would have occurred prior to this worker being invoked
          let_it_be(:project) { create(:project, namespace: non_indexed_namespace) }

          before do
            create(:elasticsearch_indexed_namespace, namespace: indexed_namespace)
          end

          it 'invalidates the cache and removes the project from the index' do
            expect(Elastic::ProcessInitialBookkeepingService).not_to receive(:backfill_projects!)
            expect(ElasticDeleteProjectWorker).to receive(:perform_async).with(project.id, project.es_id)
            expect(::Gitlab::CurrentSettings)
              .to receive(:invalidate_elasticsearch_indexes_cache_for_project!)
                    .with(project.id).and_call_original

            worker.perform(project.id, non_indexed_namespace.id, indexed_namespace.id)
          end
        end

        context 'when both namespaces are indexed' do
          let(:job_args) { [project.id, another_indexed_namespace.id, indexed_namespace.id] }

          let_it_be(:another_indexed_namespace) { create(:group) }

          before do
            create(:elasticsearch_indexed_namespace, namespace: indexed_namespace)
            create(:elasticsearch_indexed_namespace, namespace: another_indexed_namespace)
          end

          it 'does not invalidate the cache and indexes the project and associated data' do
            expect(Elastic::ProcessInitialBookkeepingService).to receive(:backfill_projects!).with(project)
            expect(::Gitlab::CurrentSettings).not_to receive(:invalidate_elasticsearch_indexes_cache_for_project!)
            expect(ElasticDeleteProjectWorker).not_to receive(:perform_async)

            worker.perform(project.id, another_indexed_namespace.id, indexed_namespace.id)
          end
        end
      end

      # in this case both namespaces would be indexed because no limiting is being done
      context 'when elasticsearch_limit_indexing is off' do
        before do
          stub_ee_application_setting(elasticsearch_limit_indexing: false)
        end

        it 'does not invalidate the cache and indexes the project and all associated data' do
          expect(Elastic::ProcessInitialBookkeepingService).to receive(:backfill_projects!).with(project)
          expect(::Gitlab::CurrentSettings).not_to receive(:invalidate_elasticsearch_indexes_cache_for_project!)
          expect(ElasticDeleteProjectWorker).not_to receive(:perform_async)

          worker.perform(project.id, non_indexed_namespace.id, indexed_namespace.id)
        end
      end
    end
  end
end
