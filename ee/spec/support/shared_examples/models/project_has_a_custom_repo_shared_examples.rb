# frozen_string_literal: true

RSpec.shared_examples 'a project has a custom repo' do |custom_repository_type|
  describe '.replicables_for_current_secondary' do
    let_it_be(:group_1) { create(:group) }
    let_it_be(:group_2) { create(:group) }
    let_it_be(:nested_group_1) { create(:group, parent: group_1) }
    let_it_be(:project_1) { create(:project, group: group_1) }
    let_it_be(:project_2) { create(:project, group: nested_group_1) }
    let_it_be(:project_3) { create(:project, :broken_storage, group: group_2) }

    let(:node) { create(:geo_node) }
    let(:start_id) { described_class.minimum(:id) }
    let(:end_id) { described_class.maximum(:id) }

    let_it_be(:custom_repository_1) { create(custom_repository_type, project: project_1) }
    let_it_be(:custom_repository_2) { create(custom_repository_type, project: project_2) }
    let_it_be(:custom_repository_3) { create(custom_repository_type, project: project_3) }

    before do
      stub_current_geo_node(node)
    end

    context 'without selective sync' do
      it 'returns all replicables' do
        replicables = described_class.replicables_for_current_secondary(start_id..end_id)

        expect(replicables)
          .to match_array([
            custom_repository_1,
            custom_repository_2,
            custom_repository_3
          ])
      end
    end

    context 'with selective sync by namespace' do
      before do
        node.update!(selective_sync_type: 'namespaces', namespaces: [group_1, nested_group_1])
      end

      it 'returns replicables that belong to the namespaces' do
        replicables = described_class.replicables_for_current_secondary(start_id..end_id)

        expect(replicables)
          .to match_array([
            custom_repository_1,
            custom_repository_2
          ])
      end

      it 'excludes replicables outside the primary key ID range' do
        replicables = described_class.replicables_for_current_secondary((start_id + 1)..end_id)

        expect(replicables)
          .to match_array([
            custom_repository_2
          ])
      end
    end

    context 'with selective sync by shard' do
      before do
        node.update!(selective_sync_type: 'shards', selective_sync_shards: ['default'])
      end

      it 'returns replicables that belong to the shards' do
        replicables = described_class.replicables_for_current_secondary(start_id..end_id)

        expect(replicables)
          .to match_array([
            custom_repository_1,
            custom_repository_2
          ])
      end

      it 'excludes replicables outside the primary key ID range' do
        replicables = described_class.replicables_for_current_secondary((start_id + 1)..end_id)

        expect(replicables)
          .to match_array([
            custom_repository_2
          ])
      end
    end
  end
end
