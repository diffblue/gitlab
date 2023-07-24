# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::IndexRepairService, feature_category: :global_search do
  let(:logger) { instance_double(::Gitlab::Elasticsearch::Logger) }
  let(:client) { instance_double(::Gitlab::Search::Client) }

  let_it_be(:project) { create(:project, :repository) }

  subject(:service) { described_class.new(project: project) }

  before do
    allow(service).to receive(:logger).and_return(logger)
    allow(service).to receive(:client).and_return(client)
    allow(logger).to receive(:warn)
  end

  shared_examples_for 'a service that does not call the search client' do
    it 'does not call the search client', :aggregate_failures do
      expect(::Gitlab::Search::Client).not_to receive(:new)
      expect(logger).not_to receive(:warn)

      service.execute
    end
  end

  shared_examples 'a service that repairs the blobs index' do
    it 'queues the blobs for indexing and logs a warning', :aggregate_failures, :freeze_time do
      expect(logger).to receive(:warn).with(a_hash_including(expected_hash)).once

      expect(ElasticCommitIndexerWorker).to receive(:perform_in).with(
        within(described_class::DELAY_INTERVAL).of(described_class::DELAY_INTERVAL),
        project.id,
        false,
        { force: true }
      )

      service.execute
    end
  end

  shared_examples 'a service that does no repair work for the blobs index' do
    it 'does not queue blobs for indexing' do
      expected_hash = {
        message: 'blob documents missing from index for project',
        class: described_class.to_s,
        namespace_id: project.namespace_id,
        root_namespace_id: project.root_namespace.id,
        project_id: project.id,
        project_last_repository_updated_at: be_within(0.05.seconds).of(project.last_repository_updated_at),
        index_status_last_commit: index_status&.last_commit,
        index_status_indexed_at: be_within(0.05.seconds).of(project.index_status&.indexed_at),
        repository_size: 100
      }.stringify_keys

      expect(logger).to receive(:warn).with(a_hash_including(expected_hash)).once

      expect(ElasticCommitIndexerWorker).not_to receive(:perform_in)

      service.execute
    end
  end

  describe '.execute', :freeze_time do
    before do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    end

    context 'when search_index_integrity feature flag is disabled' do
      before do
        stub_feature_flags(search_index_integrity: false)
      end

      it_behaves_like 'a service that does not call the search client'
    end

    context 'when project.should_check_index_integrity? is false' do
      before do
        allow(project).to receive(:should_check_index_integrity?).and_return(false)
      end

      it_behaves_like 'a service that does not call the search client'
    end

    context 'when project and blobs exist in the index' do
      before do
        blob_body = {
          query: {
            bool: {
              filter: [
                { term: { type: 'blob' } },
                { term: { project_id: project.id } }
              ]
            }
          }
        }

        project_body = {
          query: {
            bool: {
              filter: [
                { term: { type: 'project' } },
                { term: { id: project.id } }
              ]
            }
          }
        }

        allow(client).to receive(:count).with(
          index: Repository.index_name,
          body: blob_body,
          routing: project.es_id
        ).and_return({ 'count' => 10 })

        allow(client).to receive(:count).with(
          index: Project.index_name,
          body: project_body,
          routing: project.es_id
        ).and_return({ 'count' => 1 })
      end

      it 'does not log anything' do
        expect(logger).not_to receive(:warn)

        service.execute
      end
    end

    context 'when blobs are missing from the index' do
      let_it_be(:project_stats) { create(:project_statistics, project: project, repository_size: 100) }

      before do
        blob_body = { query: { bool: { filter: [{ term: { type: 'blob' } }, { term: { project_id: project.id } }] } } }
        project_body = { query: { bool: { filter: [{ term: { type: 'project' } }, { term: { id: project.id } }] } } }

        allow(client).to receive(:count).with(
          index: Repository.index_name,
          body: blob_body,
          routing: project.es_id
        ).and_return({ 'count' => 0 })

        allow(client).to receive(:count).with(
          index: Project.index_name,
          body: project_body,
          routing: project.es_id
        ).and_return({ 'count' => 1 })
      end

      context 'when index_status does not exist' do
        before do
          allow(project).to receive(:index_status).and_return(nil)
        end

        it_behaves_like 'a service that repairs the blobs index' do
          let(:expected_hash) do
            {
              message: 'blob documents missing from index for project',
              class: described_class.to_s,
              namespace_id: project.namespace_id,
              root_namespace_id: project.root_namespace.id,
              project_id: project.id,
              project_last_repository_updated_at: be_within(0.05.seconds).of(project.last_repository_updated_at),
              index_status_last_commit: nil,
              index_status_indexed_at: nil,
              repository_size: 100
            }.stringify_keys
          end
        end
      end

      context 'when index_status exists' do
        let_it_be_with_reload(:index_status) { create(:index_status, project: project) }

        context 'when index_status last_commit does not match last project commit' do
          before do
            index_status.update!(last_commit: 'FAKE_SHA')
          end

          it_behaves_like 'a service that repairs the blobs index' do
            let(:expected_hash) do
              {
                message: 'blob documents missing from index for project',
                class: described_class.to_s,
                namespace_id: project.namespace_id,
                root_namespace_id: project.root_namespace.id,
                project_id: project.id,
                project_last_repository_updated_at: be_within(0.05.seconds).of(project.last_repository_updated_at),
                index_status_last_commit: 'FAKE_SHA',
                index_status_indexed_at: index_status.indexed_at,
                repository_size: 100
              }.stringify_keys
            end
          end
        end

        context 'when index_status last_commit matches the repository head_commit' do
          it_behaves_like 'a service that does no repair work for the blobs index'
        end

        context 'when project has a null commit' do
          before do
            allow(project).to receive(:commit).and_return(nil)
          end

          it_behaves_like 'a service that does no repair work for the blobs index'
        end
      end
    end

    context 'when project is missing from the index' do
      before do
        stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

        blob_body = { query: { bool: { filter: [{ term: { type: 'blob' } }, { term: { project_id: project.id } }] } } }
        project_body = { query: { bool: { filter: [{ term: { type: 'project' } }, { term: { id: project.id } }] } } }

        allow(client).to receive(:count).with(
          index: Repository.index_name,
          body: blob_body,
          routing: project.es_id
        ).and_return({ 'count' => 20 })

        allow(client).to receive(:count).with(
          index: Project.index_name,
          body: project_body,
          routing: project.es_id
        ).and_return({ 'count' => 0 })
      end

      it 'enqueues the project for indexing and logs a warning' do
        expect(::Elastic::ProcessBookkeepingService).to receive(:track!).with(project)

        expected_hash = {
          message: 'project document missing from index',
          class: 'Search::IndexRepairService',
          namespace_id: project.namespace_id,
          root_namespace_id: project.root_namespace.id,
          project_id: project.id
        }.stringify_keys

        expect(logger).to receive(:warn).with(a_hash_including(expected_hash))

        service.execute
      end
    end
  end
end
