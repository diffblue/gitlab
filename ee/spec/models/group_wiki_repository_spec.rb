# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupWikiRepository, :geo do
  describe 'associations' do
    it { is_expected.to belong_to(:shard) }
    it { is_expected.to belong_to(:group) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:shard) }
    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:disk_path) }

    context 'uniqueness' do
      subject { described_class.new(shard: build(:shard), group: build(:group), disk_path: 'path') }

      it { is_expected.to validate_uniqueness_of(:group) }
      it { is_expected.to validate_uniqueness_of(:disk_path) }
    end
  end

  describe 'Geo Replication' do
    include EE::GeoHelpers

    let(:node) { create(:geo_node) }

    before do
      stub_current_geo_node(node)
    end

    context 'with root group and subgroup wikis' do
      let_it_be(:root_group) { create(:group) }
      let_it_be(:subgroup) { create(:group, parent: root_group) }
      let_it_be(:root_group_wiki_repository) { create(:group_wiki_repository, group: root_group) }
      let_it_be(:subgroup_wiki_repository) { create(:group_wiki_repository, group: subgroup) }
      let_it_be(:broken_wiki_repository) { create(:group_wiki_repository, shard_name: 'broken') }

      describe '#in_replicables_for_current_secondary?' do
        it 'all returns true if all are replicated' do
          [
            root_group_wiki_repository,
            subgroup_wiki_repository,
            broken_wiki_repository
          ].each do |repository|
            expect(repository.in_replicables_for_current_secondary?).to be true
          end
        end

        context 'with selective sync by namespace' do
          before do
            node.update!(selective_sync_type: 'namespaces', namespaces: [root_group])
          end

          it 'returns true for groups' do
            expect(root_group_wiki_repository.in_replicables_for_current_secondary?).to be true
          end

          it 'returns true for subgroups' do
            expect(subgroup_wiki_repository.in_replicables_for_current_secondary?).to be true
          end
        end

        context 'with selective sync by shard' do
          before do
            node.update!(selective_sync_type: 'shards', selective_sync_shards: ['default'])
          end

          it 'returns true for groups in the shard' do
            expect(root_group_wiki_repository.in_replicables_for_current_secondary?).to be true
            expect(subgroup_wiki_repository.in_replicables_for_current_secondary?).to be true
          end

          it 'returns false for group wiki repositories not in an included shard' do
            expect(broken_wiki_repository.in_replicables_for_current_secondary?).to be false
          end
        end
      end

      describe '#replicables_for_current_secondary' do
        it 'returns all group wiki repositories without selective sync' do
          expect(described_class.replicables_for_current_secondary(1..described_class.last.id)).to match_array(
            [
              root_group_wiki_repository,
              subgroup_wiki_repository,
              broken_wiki_repository
            ])
        end

        context 'with selective sync by namespace' do
          it 'returns group wiki repositories that belong to the namespaces and descendants' do
            node.update!(selective_sync_type: 'namespaces', namespaces: [root_group])

            expect(described_class.replicables_for_current_secondary(1..described_class.last.id)).to match_array(
              [
                root_group_wiki_repository,
                subgroup_wiki_repository
              ])
          end

          it 'returns group wiki repositories that belong to the namespace' do
            node.update!(selective_sync_type: 'namespaces', namespaces: [subgroup])

            expect(described_class.replicables_for_current_secondary(1..described_class.last.id)).to match_array(
              [
                subgroup_wiki_repository
              ])
          end
        end

        context 'with selective sync by shard' do
          it 'returns group wiki repositories that belong to the shards' do
            node.update!(selective_sync_type: 'shards', selective_sync_shards: ['default'])

            expect(described_class.replicables_for_current_secondary(1..described_class.last.id)).to match_array(
              [
                root_group_wiki_repository,
                subgroup_wiki_repository
              ])
          end
        end

        it 'returns nothing if an unrecognised selective sync type is used' do
          node.update_attribute(:selective_sync_type, 'unknown')

          expect(described_class.replicables_for_current_secondary(1..described_class.last.id)).to be_empty
        end
      end
    end
  end
end
