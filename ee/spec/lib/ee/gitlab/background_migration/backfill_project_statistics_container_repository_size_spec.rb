# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillProjectStatisticsContainerRepositorySize, :migration, schema: 20220622080547 do # rubocop:disable Layout/LineLength
  let!(:namespace) { table(:namespaces) }
  let!(:container_repositories_table) { table(:container_repositories) }
  let!(:project_statistics_table) { table(:project_statistics) }
  let!(:project) { table(:projects) }

  let!(:root_group) do
    namespace.create!(name: 'root-group', path: 'root-group', type: 'Group') do |new_group|
      new_group.update!(traversal_ids: [new_group.id])
    end
  end

  let!(:group) do
    namespace.create!(name: 'group', path: 'group', parent_id: root_group.id, type: 'Group') do |new_group|
      new_group.update!(traversal_ids: [root_group.id, new_group.id])
    end
  end

  let!(:sub_group) do
    namespace.create!(name: 'subgroup', path: 'subgroup', parent_id: group.id, type: 'Group') do |new_group|
      new_group.update!(traversal_ids: [root_group.id, group.id, new_group.id])
    end
  end

  let!(:namespace1) do
    namespace.create!(
      name: 'namespace1', type: 'Group', path: 'space1'
    )
  end

  let!(:proj_namespace1) do
    namespace.create!(
      name: 'proj1', path: 'proj1', type: 'Project', parent_id: namespace1.id
    )
  end

  let!(:proj_namespace2) do
    namespace.create!(
      name: 'proj2', path: 'proj2', type: 'Project', parent_id: namespace1.id
    )
  end

  let!(:proj_namespace3) do
    namespace.create!(
      name: 'proj3', path: 'proj3', type: 'Project', parent_id: sub_group.id
    )
  end

  let!(:proj_namespace4) do
    namespace.create!(
      name: 'proj4', path: 'proj4', type: 'Project', parent_id: sub_group.id
    )
  end

  let!(:proj1) do
    project.create!(
      name: 'proj1', path: 'proj1', namespace_id: namespace1.id, project_namespace_id: proj_namespace1.id
    )
  end

  let!(:proj2) do
    project.create!(
      name: 'proj2', path: 'proj2', namespace_id: namespace1.id, project_namespace_id: proj_namespace2.id
    )
  end

  let!(:proj3) do
    project.create!(
      name: 'proj3', path: 'proj3', namespace_id: sub_group.id, project_namespace_id: proj_namespace3.id
    )
  end

  let!(:proj4) do
    project.create!(
      name: 'proj4', path: 'proj4', namespace_id: sub_group.id, project_namespace_id: proj_namespace4.id
    )
  end

  let(:batch_max_value) { container_repositories_table.pluck(:project_id).max }

  let(:migration) do
    described_class.new(start_id: 1, end_id: batch_max_value,
                        batch_table: 'container_repositories', batch_column: 'project_id',
                        sub_batch_size: 1_000, pause_ms: 0,
                        connection: ApplicationRecord.connection)
  end

  before do
    stub_const('DATE_BEFORE_PHASE_1', Date.new(2022, 01, 20).freeze)
    stub_const('DATE_AFTER_PHASE_1', Date.new(2022, 02, 20).freeze)
  end

  describe '#filter_batch' do
    let(:proj_namespace5) do
      namespace.create!(
        name: 'proj5', path: 'proj5', type: 'Project', parent_id: sub_group.id
      )
    end

    let(:proj5) do
      project.create!(
        name: 'proj5', path: 'proj5', namespace_id: sub_group.id, project_namespace_id: proj_namespace5.id
      )
    end

    it 'filters out container repositories out of scope' do
      generate_records
      add_container_registries_and_project_statistics(proj5.id, 1, 'default', DATE_BEFORE_PHASE_1, sub_group.id)

      expected = container_repositories_table.where.not(project_id: proj5.id).pluck(:project_id).uniq
      actual = migration.filter_batch(container_repositories_table).pluck(:project_id)

      expect(actual).to match_array(expected)
    end
  end

  describe '#perform' do
    subject(:perform_migration) { migration.perform }

    context 'when project_statistics backfill runs' do
      before do
        allow(::Gitlab).to receive(:com?).and_return(true)
        allow(::ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(true)
      end

      context 'when project_statistics.container_registry_size is zero' do
        before do
          generate_records
          allow(::ContainerRegistry::GitlabApiClient).to receive(:deduplicated_size).and_return(3000)
        end

        it 'calls deduplicated_size API' do
          allow(::Namespaces::ScheduleAggregationWorker).to receive(:perform_async)

          perform_migration

          expect(::ContainerRegistry::GitlabApiClient).to have_received(:supports_gitlab_api?).exactly(4).times
        end

        context 'when the Container Registry deduplicated_size is non-zero' do
          it 'schedules Namespaces::ScheduleAggregationWorker' do
            allow(::Namespaces::ScheduleAggregationWorker).to receive(:perform_async)
            allow(::Rails).to receive_message_chain(:cache, :delete).and_return(true)

            perform_migration

            expect(::Rails.cache).to have_received(:delete).exactly(4).times
            expect(::Namespaces::ScheduleAggregationWorker).to have_received(:perform_async).exactly(4).times
          end
        end

        context 'when the Container Registry deduplicated_size is zero' do
          it 'does not schedules Namespaces::ScheduleAggregationWorker' do
            allow(::ContainerRegistry::GitlabApiClient).to receive(:deduplicated_size).and_return(0)

            perform_migration

            expect(::Namespaces::ScheduleAggregationWorker).not_to receive(:perform_async)
          end
        end
      end

      context 'when project_statistics.container_registry_size is non-zero' do
        before do
          generate_records(333)
        end

        it "doesn't call deduplicated_size API and schedules Namespaces::ScheduleAggregationWorker" do
          allow(::Namespaces::ScheduleAggregationWorker).to receive(:perform_async)
          allow(::Rails).to receive_message_chain(:cache, :delete).and_return(true)

          perform_migration

          expect(::ContainerRegistry::GitlabApiClient).not_to receive(:deduplicated_size)
          expect(::Rails.cache).to have_received(:delete).exactly(4).times
          expect(::Namespaces::ScheduleAggregationWorker).to have_received(:perform_async).exactly(4).times
        end
      end
    end
  end

  private

  def add_container_registries_and_project_statistics(
    project_id,
    count,
    migration_state,
    created_at,
    namespace_id,
    con_reg_size = 0
  )
    project_statistics_table.create!(
      project_id: project_id,
      namespace_id: namespace_id,
      container_registry_size: con_reg_size
    )

    count.times do |indx|
      container_repositories_table.create!(
        project_id: project_id,
        name: "ContReg_#{project_id}:#{indx}",
        migration_state: migration_state,
        created_at: created_at
      )
    end
  end

  def generate_records(container_registry_size = 0)
    add_container_registries_and_project_statistics(
      proj1.id,
      2,
     'import_done',
     DATE_BEFORE_PHASE_1,
     namespace1.id,
     container_registry_size
    )
    add_container_registries_and_project_statistics(
      proj2.id,
      3,
      'import_done',
      DATE_BEFORE_PHASE_1,
      namespace1.id,
      container_registry_size
    )
    add_container_registries_and_project_statistics(
      proj3.id,
      1,
      'import_done',
      DATE_BEFORE_PHASE_1,
      sub_group.id,
      container_registry_size
    )
    add_container_registries_and_project_statistics(
      proj4.id,
      2,
      'default',
      DATE_AFTER_PHASE_1,
      sub_group.id,
      container_registry_size
    )
  end
end
