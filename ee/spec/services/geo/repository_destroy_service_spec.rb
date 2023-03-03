# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RepositoryDestroyService, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  let_it_be(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#async_execute' do
    it 'starts the worker' do
      project = create(:project)
      subject = described_class.new(project.id, project.name, project.disk_path, project.repository_storage)

      expect(GeoRepositoryDestroyWorker).to receive(:perform_async)

      subject.async_execute
    end
  end

  describe '#execute' do
    context 'with a project on a legacy storage' do
      let(:project) { create(:project_empty_repo, :legacy_storage, :wiki_repo) }
      let(:repository_disk_path) { "#{project.disk_path}.git" }
      let(:wiki_disk_path) { "#{project.disk_path}.wiki.git" }

      subject(:service) { described_class.new(project.id, project.name, project.disk_path, project.repository_storage) }

      it 'delegates project removal to Projects::DestroyService#geo_replicate' do
        expect_next_instance_of(Projects::DestroyService) do |destroy_service|
          expect(destroy_service).to receive(:geo_replicate).once
        end

        service.execute
      end

      it 'removes the repository/wiki repositories' do
        expect { service.execute }.to change { project.gitlab_shell.repository_exists?(project.repository_storage, repository_disk_path) }.to(false)
                                  .and change { project.gitlab_shell.repository_exists?(project.repository_storage, wiki_disk_path) }.to(false)
      end

      it 'removes the tracking entries' do
        create(:geo_project_registry, project: project)
        create(:geo_design_registry, project: project)

        service.execute

        expect(Geo::ProjectRegistry.where(project: project)).to be_empty
        expect(Geo::DesignRegistry.where(project: project)).to be_empty
      end
    end

    context 'with a project on a hashed storage' do
      let(:project) { create(:project_empty_repo, :wiki_repo) }
      let(:repository_disk_path) { "#{project.disk_path}.git" }
      let(:wiki_disk_path) { "#{project.disk_path}.wiki.git" }

      subject(:service) { described_class.new(project.id, project.name, project.disk_path, project.repository_storage) }

      it 'delegates project removal to Projects::DestroyService' do
        expect_next_instance_of(Projects::DestroyService) do |destroy_service|
          expect(destroy_service).to receive(:geo_replicate).once
        end

        service.execute
      end

      it 'removes the repository/wiki repositories' do
        expect(project.gitlab_shell.repository_exists?(project.repository_storage, repository_disk_path)).to be_truthy
        expect(project.gitlab_shell.repository_exists?(project.repository_storage, wiki_disk_path)).to be_truthy

        service.execute

        expect(project.gitlab_shell.repository_exists?(project.repository_storage, repository_disk_path)).to be_falsey
        expect(project.gitlab_shell.repository_exists?(project.repository_storage, wiki_disk_path)).to be_falsey
      end

      it 'removes the tracking entries' do
        create(:geo_project_registry, project: project)
        create(:geo_design_registry, project: project)

        service.execute

        expect(Geo::ProjectRegistry.where(project: project)).to be_empty
        expect(Geo::DesignRegistry.where(project: project)).to be_empty
      end
    end

    context 'with a project on a broken storage' do
      let(:project) { create(:project, :broken_storage) }

      subject(:service) { described_class.new(project.id, project.name, project.disk_path, project.repository_storage) }

      it 'delegates project removal to Projects::DestroyService' do
        expect_next_instance_of(Projects::DestroyService) do |destroy_service|
          expect(destroy_service).to receive(:geo_replicate).once
        end

        service.execute
      end

      it 'removes the tracking entries' do
        create(:geo_project_registry, project: project)
        create(:geo_design_registry, project: project)

        expect { service.execute }.to raise_error RuntimeError, 'storage not found: "broken"'

        expect(Geo::ProjectRegistry.where(project: project)).to be_empty
        expect(Geo::DesignRegistry.where(project: project)).to be_empty
      end
    end

    context 'with an unused registry' do
      let!(:project) { create(:project_empty_repo, :legacy_storage) }
      let!(:unused_project_registry) { create(:geo_project_registry, project_id: project.id) }
      let!(:unused_design_registry) { create(:geo_design_registry, project_id: project.id) }

      subject(:service) { described_class.new(project.id) }

      context 'when the replicable model does not exist' do
        before do
          project.delete
        end

        it 'does not delegate project removal to Projects::DestroyService' do
          expect_any_instance_of(EE::Projects::DestroyService).not_to receive(:geo_replicate)

          service.execute
        end

        it 'removes the registry entries' do
          service.execute

          expect(Geo::ProjectRegistry.where(project: project)).to be_empty
          expect(Geo::DesignRegistry.where(project: project)).to be_empty
        end
      end

      context 'when the replicable model exists' do
        subject(:service) { described_class.new(project.id) }

        it 'delegates project removal to Projects::DestroyService' do
          expect_next_instance_of(Projects::DestroyService) do |destroy_service|
            expect(destroy_service).to receive(:geo_replicate).once
          end

          service.execute
        end

        it 'removes the registry entries' do
          service.execute

          expect(Geo::ProjectRegistry.where(project: project)).to be_empty
          expect(Geo::DesignRegistry.where(project: project)).to be_empty
        end
      end
    end
  end
end
