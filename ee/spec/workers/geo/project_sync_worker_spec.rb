# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ProjectSyncWorker, feature_category: :geo_replication do
  let_it_be(:project) { create(:project) }

  before do
    allow(Gitlab::ShardHealthCache).to receive(:healthy_shard?)
      .with(project.repository_storage).and_return(true)
  end

  describe '#perform' do
    let(:wiki_sync_service) { spy }
    let(:repository_sync_service) { spy }

    before do
      allow(Geo::WikiSyncService).to receive(:new)
        .with(instance_of(Project)).once.and_return(wiki_sync_service)

      allow(Geo::RepositorySyncService).to receive(:new)
        .with(instance_of(Project)).and_return(repository_sync_service)
    end

    context 'when project could not be found' do
      it 'logs an error and returns' do
        expect(subject).to receive(:log_error).with("Couldn't find project, skipping syncing", project_id: non_existing_record_id)

        expect { subject.perform(non_existing_record_id) }.not_to raise_error
      end
    end

    context 'when the shard associated to the project is unhealthy' do
      let_it_be(:project_with_broken_storage) { create(:project, :broken_storage) }

      it 'logs an error and returns' do
        allow(Gitlab::ShardHealthCache).to receive(:healthy_shard?)
          .with(project_with_broken_storage.repository_storage).once.and_return(false)

        expect(subject).to receive(:log_error).with("Project shard '#{project_with_broken_storage.repository_storage}' is unhealthy, skipping syncing", project_id: project_with_broken_storage.id)
        expect(repository_sync_service).not_to receive(:execute)
        expect(wiki_sync_service).not_to receive(:execute)

        subject.perform(project_with_broken_storage.id)
      end
    end

    context 'when project repositories has never been synced' do
      it 'performs Geo::RepositorySyncService for the given project' do
        subject.perform(project.id, sync_repository: true)

        expect(repository_sync_service).to have_received(:execute).once
        expect(wiki_sync_service).not_to have_received(:execute)
      end

      context 'with geo_project_wiki_repository_replication feature flag disabled' do
        before do
          stub_feature_flags(geo_project_wiki_repository_replication: false)
        end

        it 'performs Geo::WikiSyncService for the given project' do
          subject.perform(project.id, sync_wiki: true)

          expect(wiki_sync_service).to have_received(:execute).once
          expect(repository_sync_service).not_to have_received(:execute)
        end
      end

      context 'with geo_project_wiki_repository_replication feature flag enabled' do
        before do
          stub_feature_flags(geo_project_wiki_repository_replication: true)
        end

        it 'does not perform Geo::WikiSyncService for the given project' do
          subject.perform(project.id, sync_wiki: true)

          expect(wiki_sync_service).not_to have_received(:execute)
        end
      end
    end

    context 'when project repositories has been synced' do
      let!(:registry) { create(:geo_project_registry, :synced, project: project) }

      it 'does not perform Geo::RepositorySyncService for the given project' do
        subject.perform(project.id, sync_repository: true)

        expect(repository_sync_service).not_to have_received(:execute)
      end

      context 'with geo_project_wiki_repository_replication feature flag disabled' do
        before do
          stub_feature_flags(geo_project_wiki_repository_replication: false)
        end

        it 'does not perform Geo::WikiSyncService for the given project' do
          subject.perform(project.id, sync_wiki: true)

          expect(wiki_sync_service).not_to have_received(:execute)
        end
      end

      context 'with geo_project_wiki_repository_replication feature flag enabled' do
        before do
          stub_feature_flags(geo_project_wiki_repository_replication: true)
        end

        it 'does not perform Geo::WikiSyncService for the given project' do
          subject.perform(project.id, sync_wiki: true)

          expect(wiki_sync_service).not_to have_received(:execute)
        end
      end
    end

    context 'when last attempt to sync project repositories failed' do
      let!(:registry) { create(:geo_project_registry, :sync_failed, project: project) }

      it 'performs Geo::RepositorySyncService for the given project' do
        subject.perform(project.id, sync_repository: true)

        expect(repository_sync_service).to have_received(:execute).once
      end

      context 'with geo_project_wiki_repository_replication feature flag disabled' do
        before do
          stub_feature_flags(geo_project_wiki_repository_replication: false)
        end

        it 'performs Geo::WikiSyncService for the given project' do
          subject.perform(project.id, sync_wiki: true)

          expect(wiki_sync_service).to have_received(:execute).once
        end
      end

      context 'with geo_project_wiki_repository_replication feature flag enabled' do
        before do
          stub_feature_flags(geo_project_wiki_repository_replication: true)
        end

        it 'does not perform Geo::WikiSyncService for the given project' do
          subject.perform(project.id, sync_wiki: true)

          expect(wiki_sync_service).not_to have_received(:execute)
        end
      end
    end
  end

  describe 'idempotence' do
    include_examples 'an idempotent worker' do
      let(:job_args) { [project.id, { sync_repository: true }] }

      before do
        allow_next_instance_of(Geo::RepositorySyncService) do |service|
          allow(service).to receive(:fetch_repository)
        end
      end

      context 'when the project registry row does not exist' do
        it 'creates exactly 1 project registry row' do
          expect { subject }.to change { Geo::ProjectRegistry.count }.by(1)
        end
      end

      context 'when the project registry row already exists' do
        it 'does not create a project registry row' do
          create(:geo_project_registry, :synced, project: project)

          expect { subject }.not_to change { Geo::ProjectRegistry.count }
        end
      end
    end
  end
end
