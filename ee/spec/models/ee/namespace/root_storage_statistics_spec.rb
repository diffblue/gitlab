# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Namespace::RootStorageStatistics, feature_category: :consumables_cost_management do
  describe '#recalculate!' do
    let(:root_storage_statistics) { create(:namespace_root_storage_statistics, namespace: namespace) }

    context 'when namespace belongs to a group' do
      let_it_be(:root_group) { create(:group) }
      let_it_be(:group1) { create(:group, parent: root_group) }
      let_it_be(:subgroup1) { create(:group, parent: group1) }
      let_it_be(:group2) { create(:group, parent: root_group) }
      let_it_be(:project1) { create(:project, namespace: group1) }
      let_it_be(:project2) { create(:project, namespace: group2) }
      let_it_be(:project_stat1) do
        create(:project_statistics, project: project1, with_data: true, size_multiplier: 100)
      end

      let_it_be(:project_stat2) do
        create(:project_statistics, project: project2, with_data: true, size_multiplier: 100)
      end

      let_it_be(:root_namespace_stat) do
        create(:namespace_statistics, namespace: root_group, storage_size: 100, wiki_size: 100)
      end

      let_it_be(:group1_namespace_stat) do
        create(:namespace_statistics, namespace: group1, storage_size: 200, wiki_size: 200)
      end

      let_it_be(:group2_namespace_stat) do
        create(:namespace_statistics, namespace: group2, storage_size: 300, wiki_size: 300)
      end

      let_it_be(:subgroup1_namespace_stat) do
        create(:namespace_statistics, namespace: subgroup1, storage_size: 300, wiki_size: 100)
      end

      let(:namespace) { root_group }

      it 'aggregates namespace wiki statistics' do
        # This group is not a descendant of the root_group so it shouldn't be included in the final stats.
        other_group = create(:group)
        create(:namespace_statistics, namespace: other_group, storage_size: 500, wiki_size: 500)

        root_storage_statistics.recalculate!

        root_storage_statistics.reload

        total_wiki_size = project_stat1.wiki_size + project_stat2.wiki_size + root_namespace_stat.wiki_size +
          group1_namespace_stat.wiki_size + group2_namespace_stat.wiki_size + subgroup1_namespace_stat.wiki_size
        total_storage_size = project_stat1.storage_size + project_stat2.storage_size +
          root_namespace_stat.storage_size + group1_namespace_stat.storage_size +
          group2_namespace_stat.storage_size + subgroup1_namespace_stat.storage_size

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

  describe '#cost_factored_storage_size', :saas do
    let_it_be(:group) { create(:group_with_plan, plan: :ultimate_plan) }

    before do
      stub_ee_application_setting(check_namespace_plan: true)
    end

    context 'with a cost factor for forks' do
      before do
        stub_ee_application_setting(namespace_storage_forks_cost_factor: 0.05)
      end

      context 'with a free plan' do
        let_it_be(:group) { create(:group_with_plan, plan: :free_plan) }

        it 'includes public forks storage in the cost factor reduction' do
          statistics = create(:namespace_root_storage_statistics, namespace: group, storage_size: 1000,
            public_forks_storage_size: 100)

          expect(statistics.cost_factored_storage_size).to eq(905)
        end

        it 'includes internal forks storage in the cost factor reduction' do
          statistics = create(:namespace_root_storage_statistics, namespace: group, storage_size: 1000,
            internal_forks_storage_size: 200)

          expect(statistics.cost_factored_storage_size).to eq(810)
        end

        it 'does not include private forks storage in the cost factor reduction' do
          statistics = create(:namespace_root_storage_statistics, namespace: group, storage_size: 1000,
            private_forks_storage_size: 400)

          expect(statistics.cost_factored_storage_size).to eq(1000)
        end

        it 'applies the cost factor for both public and internal forks excluding private forks' do
          statistics = create(:namespace_root_storage_statistics, namespace: group, storage_size: 1000,
            public_forks_storage_size: 100, internal_forks_storage_size: 200, private_forks_storage_size: 400)

          expect(statistics.cost_factored_storage_size).to eq(715)
        end
      end

      context 'with a paid plan' do
        it 'includes public forks storage in the cost factor reduction' do
          statistics = create(:namespace_root_storage_statistics, namespace: group, storage_size: 1000,
            public_forks_storage_size: 100)

          expect(statistics.cost_factored_storage_size).to eq(905)
        end

        it 'includes internal forks storage in the cost factor reduction' do
          statistics = create(:namespace_root_storage_statistics, namespace: group, storage_size: 1000,
            internal_forks_storage_size: 200)

          expect(statistics.cost_factored_storage_size).to eq(810)
        end

        it 'includes private forks storage in the cost factor reduction' do
          statistics = create(:namespace_root_storage_statistics, namespace: group, storage_size: 1000,
            private_forks_storage_size: 400)

          expect(statistics.cost_factored_storage_size).to eq(620)
        end

        it 'applies the cost factor for public, internal, and private forks' do
          statistics = create(:namespace_root_storage_statistics, namespace: group, storage_size: 1000,
            public_forks_storage_size: 100, internal_forks_storage_size: 200, private_forks_storage_size: 400)

          expect(statistics.cost_factored_storage_size).to eq(335)
        end
      end
    end

    context 'with a fork cost factor of 1' do
      before do
        stub_ee_application_setting(namespace_storage_forks_cost_factor: 1.0)
      end

      it 'considers forks to take up their full actual disk storage' do
        statistics = create(:namespace_root_storage_statistics, namespace: group, storage_size: 1000,
          public_forks_storage_size: 100, internal_forks_storage_size: 200, private_forks_storage_size: 300)

        expect(statistics.cost_factored_storage_size).to eq(1000)
      end
    end

    context 'with a fork cost factor of 0' do
      before do
        stub_ee_application_setting(namespace_storage_forks_cost_factor: 0)
      end

      it 'considers forks to take up no storage at all' do
        statistics = create(:namespace_root_storage_statistics, namespace: group, storage_size: 1000,
          public_forks_storage_size: 100, internal_forks_storage_size: 200, private_forks_storage_size: 300)

        expect(statistics.cost_factored_storage_size).to eq(400)
      end
    end

    context 'when the cost factor would result in a fractional storage_size' do
      before do
        stub_ee_application_setting(namespace_storage_forks_cost_factor: 0.1)
      end

      it 'rounds to the nearest integer' do
        statistics = create(:namespace_root_storage_statistics, namespace: group, storage_size: 1000,
          public_forks_storage_size: 502)

        expect(statistics.cost_factored_storage_size).to eq(548)
      end
    end
  end
end
