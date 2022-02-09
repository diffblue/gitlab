# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Namespace::RootStorageStatistics do
  describe '#recalculate!' do
    let(:root_storage_statistics) { create(:namespace_root_storage_statistics, namespace: namespace) }

    context 'when namespace belongs to a group' do
      let_it_be(:root_group) { create(:group) }
      let_it_be(:group1) { create(:group, parent: root_group) }
      let_it_be(:subgroup1) { create(:group, parent: group1) }
      let_it_be(:group2) { create(:group, parent: root_group) }
      let_it_be(:project1) { create(:project, namespace: group1) }
      let_it_be(:project2) { create(:project, namespace: group2) }
      let_it_be(:project_stat1) { create(:project_statistics, project: project1, with_data: true, size_multiplier: 100) }
      let_it_be(:project_stat2) { create(:project_statistics, project: project2, with_data: true, size_multiplier: 100) }
      let_it_be(:root_namespace_stat) { create(:namespace_statistics, namespace: root_group, storage_size: 100, wiki_size: 100) }
      let_it_be(:group1_namespace_stat) { create(:namespace_statistics, namespace: group1, storage_size: 200, wiki_size: 200) }
      let_it_be(:group2_namespace_stat) { create(:namespace_statistics, namespace: group2, storage_size: 300, wiki_size: 300) }
      let_it_be(:subgroup1_namespace_stat) { create(:namespace_statistics, namespace: subgroup1, storage_size: 300, wiki_size: 100) }

      let(:namespace) { root_group }

      it 'aggregates namespace wiki statistics' do
        # This group is not a descendant of the root_group so it shouldn't be included in the final stats.
        other_group = create(:group)
        create(:namespace_statistics, namespace: other_group, storage_size: 500, wiki_size: 500)

        root_storage_statistics.recalculate!

        root_storage_statistics.reload

        total_wiki_size = project_stat1.wiki_size + project_stat2.wiki_size + root_namespace_stat.wiki_size + group1_namespace_stat.wiki_size + group2_namespace_stat.wiki_size + subgroup1_namespace_stat.wiki_size
        total_storage_size = project_stat1.storage_size + project_stat2.storage_size + root_namespace_stat.storage_size + group1_namespace_stat.storage_size + group2_namespace_stat.storage_size + subgroup1_namespace_stat.storage_size

        expect(root_storage_statistics.storage_size).to eq(total_storage_size)
        expect(root_storage_statistics.wiki_size).to eq(total_wiki_size)
      end

      it 'works when there are no namespace statistics' do
        NamespaceStatistics.delete_all

        root_storage_statistics.recalculate!

        root_storage_statistics.reload

        total_wiki_size = project_stat1.wiki_size + project_stat2.wiki_size
        total_storage_size = project_stat1.storage_size + project_stat2.storage_size

        expect(root_storage_statistics.storage_size).to eq(total_storage_size)
        expect(root_storage_statistics.wiki_size).to eq(total_wiki_size)
      end
    end

    context 'when namespace belong to a user' do
      let_it_be(:user) { create(:user) }
      let_it_be(:project) { create(:project, namespace: user.namespace) }
      let_it_be(:project_stat) { create(:project_statistics, project: project, with_data: true, size_multiplier: 100) }

      let(:namespace) { user.namespace }

      it 'does not aggregate namespace statistics' do
        create(:namespace_statistics, namespace: user.namespace, storage_size: 200, wiki_size: 200)

        root_storage_statistics.recalculate!

        root_storage_statistics.reload

        expect(root_storage_statistics.storage_size).to eq(project_stat.storage_size)
        expect(root_storage_statistics.wiki_size).to eq(project_stat.wiki_size)
      end
    end
  end
end
