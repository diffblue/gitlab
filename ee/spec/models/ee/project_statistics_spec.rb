# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectStatistics do
  using RSpec::Parameterized::TableSyntax

  describe '#update_storage_size' do
    let_it_be(:project) { create(:project) }
    let_it_be(:statistics) { project.statistics }
    let_it_be(:other_sizes) { 3 }
    let_it_be(:uploads_size) { 5 }

    context 'when should_check_namespace_plan? returns true' do
      before do
        stub_ee_application_setting(should_check_namespace_plan: true)
      end

      it "sums the relevant storage counters without uploads_size" do
        statistics.update!(
          repository_size: other_sizes,
          wiki_size: other_sizes,
          lfs_objects_size: other_sizes,
          snippets_size: other_sizes,
          pipeline_artifacts_size: other_sizes,
          build_artifacts_size: other_sizes,
          packages_size: other_sizes,
          uploads_size: uploads_size
        )

        statistics.reload

        expect(statistics.storage_size).to eq(other_sizes * 6)
      end
    end

    context 'when should_check_namespace_plan? returns false' do
      it "sums the relevant storage counters along with uploads_size" do
        statistics.update!(
          repository_size: other_sizes,
          wiki_size: other_sizes,
          lfs_objects_size: other_sizes,
          snippets_size: other_sizes,
          pipeline_artifacts_size: other_sizes,
          build_artifacts_size: other_sizes,
          packages_size: other_sizes,
          uploads_size: uploads_size
        )

        statistics.reload

        expect(statistics.storage_size).to eq(other_sizes * 6 + uploads_size)
      end
    end
  end

  describe '#cost_factored_storage_size', :saas do
    let_it_be(:project) { create(:project) }
    let_it_be(:fork_network) { create(:fork_network, root_project: project) }

    context 'when there is no cost factor for forks' do
      where(:plan, :fork_visibility) do
        :free_plan       | :public
        :free_plan       | :internal
        :free_plan       | :private
        :premium_plan    | :public
        :premium_plan    | :internal
        :premium_plan    | :private
        :ultimate_plan   | :public
        :ultimate_plan   | :internal
        :ultimate_plan   | :private
      end

      with_them do
        it 'equals the storage size' do
          statistics = create_fork(plan: plan, fork_visibility: fork_visibility, repository_size: 500)

          expect(statistics.cost_factored_storage_size).to eq(500)
        end
      end
    end

    context 'when there is a cost factor for forks' do
      before do
        stub_ee_application_setting(check_namespace_plan: true)
        stub_ee_application_setting(namespace_storage_forks_cost_factor: 0.1)
      end

      where(:plan, :fork_visibility) do
        :free_plan       | :public
        :free_plan       | :internal
        :premium_plan    | :public
        :premium_plan    | :internal
        :premium_plan    | :private
        :ultimate_plan   | :public
        :ultimate_plan   | :internal
        :ultimate_plan   | :private
      end

      with_them do
        it 'returns the storage size with the cost factor applied' do
          statistics = create_fork(plan: plan, fork_visibility: fork_visibility, repository_size: 100)

          expect(statistics.cost_factored_storage_size).to eq(10)
        end
      end

      it 'returns the storage size if the fork namespace is free and the fork is private' do
        statistics = create_fork(plan: :free_plan, fork_visibility: :private, repository_size: 300)

        expect(statistics.cost_factored_storage_size).to eq(300)
      end

      it 'returns the storage size with the cost factor applied for a fork in a subgroup' do
        group = create(:group_with_plan, plan: :ultimate_plan)
        subgroup = create(:group, parent: group)
        project_fork = create(:project, :private, group: subgroup)
        create(:fork_network_member, project: project_fork,
          fork_network: fork_network, forked_from_project: project)
        statistics = project_fork.statistics.reload
        statistics.update!(repository_size: 650)

        expect(statistics.cost_factored_storage_size).to eq(65)
      end

      it 'returns the storage size if the project is not a fork' do
        group = create(:group_with_plan, plan: :ultimate_plan)
        project = create(:project, :public, group: group)
        statistics = project.statistics.reload
        statistics.update!(repository_size: 200)

        expect(statistics.cost_factored_storage_size).to eq(200)
      end

      it 'rounds to the nearest integer' do
        statistics = create_fork(plan: :free_plan, fork_visibility: :public, repository_size: 305)

        expect(statistics.cost_factored_storage_size).to eq(31)
      end
    end

    def create_fork(plan:, fork_visibility:, repository_size:)
      group = create(:group_with_plan, plan: plan)
      project_fork = create(:project, fork_visibility, group: group)
      create(:fork_network_member, project: project_fork,
        fork_network: fork_network, forked_from_project: project)
      statistics = project_fork.statistics.reload
      statistics.update!(repository_size: repository_size)

      statistics
    end
  end
end
