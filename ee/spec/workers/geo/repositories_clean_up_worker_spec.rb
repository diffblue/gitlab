# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RepositoriesCleanUpWorker, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  describe '#perform' do
    let_it_be(:secondary, refind: true) { create(:geo_node) }
    let_it_be(:synced_group) { create(:group) }
    let_it_be(:synced_subgroup) { create(:group, parent: synced_group) }
    let_it_be(:unsynced_group) { create(:group) }
    let_it_be(:project_1) { create(:project, group: synced_group) }
    let_it_be(:project_2) { create(:project, group: synced_group) }
    let_it_be(:project_3) { create(:project, :repository, group: unsynced_group) }
    let_it_be(:project_4) { create(:project, :repository, group: unsynced_group) }
    let_it_be(:project_5) { create(:project, group: synced_subgroup) }
    let_it_be(:project_6) { create(:project, group: synced_subgroup) }
    let_it_be(:project_7) { create(:project) }
    let_it_be(:project_8) { create(:project) }

    before_all do
      create(:geo_project_registry, project: project_1)
      create(:geo_project_registry, project: project_2)
      create(:geo_project_registry, project: project_4)
      create(:geo_project_registry, project: project_5)
      create(:geo_project_registry, project: project_6)
      create(:geo_project_registry, project: project_7)
      create(:geo_project_registry, project: project_8)
    end

    before do
      stub_current_geo_node(secondary)
      stub_exclusive_lease
    end

    it 'does not perform Geo::RepositoryCleanupWorker when cannnot obtain a lease' do
      stub_exclusive_lease_taken

      expect(Geo::RepositoryCleanupWorker).not_to receive(:perform_async)

      subject.perform(secondary.id)
    end

    it 'does not raise an error when node could not be found' do
      expect { subject.perform(-1) }.not_to raise_error
    end

    context 'without selective sync' do
      it 'does not perform Geo::RepositoryCleanupWorker' do
        expect(Geo::RepositoryCleanupWorker).not_to receive(:perform_async)

        subject.perform(secondary.id)
      end
    end

    context 'with selective sync by namespace' do
      before do
        secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
      end

      it 'performs the clean up worker for projects that does not belong to the selected namespaces' do
        [project_4, project_7, project_8].each do |project|
          expect(Geo::RepositoryCleanupWorker).to receive(:perform_async)
            .with(project.id, project.name, project.disk_path, project.repository.storage)
            .once
            .and_return(1)
        end

        [project_1, project_2, project_3, project_5, project_6].each do |project|
          expect(Geo::RepositoryCleanupWorker).not_to receive(:perform_async)
            .with(project.id, project.name, project.disk_path, project.repository.storage)
        end

        subject.perform(secondary.id)
      end

      it 'does not leave orphaned entries in the project_registry table', :sidekiq_inline do
        subject.perform(secondary.id)

        expect(Geo::ProjectRegistry.where(project_id: [project_3, project_4, project_7, project_8])).to be_empty
      end
    end

    context 'with selective sync by shard' do
      before do
        project_7.update_column(:repository_storage, 'broken')
        project_8.update_column(:repository_storage, 'broken')

        secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])
      end

      it 'performs the clean up worker for synced projects that does not belong to the selected shards' do
        [project_1, project_2, project_4, project_5, project_6].each do |project|
          expect(Geo::RepositoryCleanupWorker).to receive(:perform_async)
            .with(project.id, project.name, project.disk_path, project.repository.storage)
            .once
            .and_return(1)
        end

        [project_3, project_7, project_8].each do |project|
          expect(Geo::RepositoryCleanupWorker).not_to receive(:perform_async)
            .with(project.id, project.name, project.disk_path, project.repository.storage)
        end

        subject.perform(secondary.id)
      end

      it 'does not leave orphaned entries in the project_registry table', :sidekiq_inline do
        subject.perform(secondary.id)

        expect(Geo::ProjectRegistry.where(project_id: [project_1, project_2, project_3, project_4, project_5, project_6])).to be_empty
      end
    end
  end
end
