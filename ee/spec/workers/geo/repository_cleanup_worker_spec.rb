# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RepositoryCleanupWorker, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  describe '#perform' do
    let_it_be(:primary) { create(:geo_node, :primary) }
    let_it_be(:secondary) { create(:geo_node) }
    let_it_be(:project) { create(:project) }

    before do
      stub_current_geo_node(secondary)
    end

    it 'skips repository clean up if the current node is a primary' do
      stub_current_geo_node(primary)

      expect_any_instance_of(Geo::RepositoryDestroyService).not_to receive(:execute)

      described_class.new.perform(project.id, project.name, project.path, 'default')
    end

    context 'when node does not have selective sync restriction' do
      it 'does not delegate project removal' do
        expect_any_instance_of(Geo::RepositoryDestroyService).not_to receive(:execute)

        described_class.new.perform(project.id, project.name, project.path, 'default')
      end
    end

    context 'when node has selective sync restriction' do
      let(:group_1) { create(:group) }
      let(:group_2) { create(:group) }

      before do
        secondary.update!(selective_sync_type: 'namespaces', namespaces: [group_1])
      end

      it 'does not delegate project removal for projects that belong to selected namespaces to replicate' do
        project = create(:project, group: group_1)

        expect_any_instance_of(Geo::RepositoryDestroyService).not_to receive(:execute)

        described_class.new.perform(project.id, project.name, project.path, 'default')
      end

      it 'delegates project removal for projects that do not belong to selected namespaces to replicate' do
        project = create(:project, group: group_2)

        expect_any_instance_of(Geo::RepositoryDestroyService).to receive(:execute)

        described_class.new.perform(project.id, project.name, project.path, 'default')
      end
    end
  end
end
