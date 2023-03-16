# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GeoRepositoryDestroyWorker, :geo, feature_category: :geo_replication do
  describe '#perform' do
    let(:project) { create(:project) }

    context 'with an existing project' do
      it 'delegates project removal to Geo::RepositoryDestroyService' do
        expect_next_instance_of(Geo::RepositoryDestroyService) do |instance|
          expect(instance).to receive(:execute)
        end

        subject.perform(project.id, project.name, project.path, 'default')
      end
    end

    context 'with project ID from an orphaned registry' do
      it 'delegates project removal to Geo::RepositoryDestroyService' do
        registry = create(:geo_project_registry, project_id: project.id)
        project.delete

        expect_next_instance_of(Geo::RepositoryDestroyService) do |instance|
          expect(instance).to receive(:execute)
        end

        subject.perform(registry.project_id)
      end
    end
  end
end
