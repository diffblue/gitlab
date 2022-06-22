# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillProjectStatisticsContainerRepositorySize, :migration, schema: 20220622080547 do # rubocop:disable Layout/LineLength
  let_it_be(:namespace) { table(:namespaces) }
  let_it_be(:container_repositories_table) { table(:container_repositories) }
  let_it_be(:project_statistics_table) { table(:project_statistics) }
  let_it_be(:project) { table(:projects) }

  let_it_be(:namespace1) do
    namespace.create!(
      name: 'namespace1', type: 'Group', path: 'space1'
    )
  end

  let_it_be(:namespace2) do
    namespace.create!(
      name: 'namespace2', type: 'Group', path: 'space2'
    )
  end

  let_it_be(:proj_namespace1) do
    namespace.create!(
      name: 'proj1', path: 'proj1', type: 'Project', parent_id: namespace1.id
    )
  end

  let_it_be(:proj_namespace2) do
    namespace.create!(
      name: 'proj2', path: 'proj2', type: 'Project', parent_id: namespace1.id
    )
  end

  let_it_be(:proj_namespace3) do
    namespace.create!(
      name: 'proj3', path: 'proj3', type: 'Project', parent_id: namespace2.id
    )
  end

  let_it_be(:proj_namespace4) do
    namespace.create!(
      name: 'proj4', path: 'proj4', type: 'Project', parent_id: namespace2.id
    )
  end

  let_it_be(:proj11) do
    project.create!(
      name: 'proj11', path: 'proj11', namespace_id: namespace1.id, project_namespace_id: proj_namespace1.id
    )
  end

  let_it_be(:proj12) do
    project.create!(
      name: 'proj12', path: 'proj12', namespace_id: namespace1.id, project_namespace_id: proj_namespace2.id
    )
  end

  let_it_be(:proj21) do
    project.create!(
      name: 'proj21', path: 'proj21', namespace_id: namespace2.id, project_namespace_id: proj_namespace3.id
    )
  end

  let_it_be(:proj22) do
    project.create!(
      name: 'proj22', path: 'proj22', namespace_id: namespace2.id, project_namespace_id: proj_namespace4.id
    )
  end

  before do
    stub_const('DATE_BEFORE_PHASE_1', Date.new(2022, 01, 20).freeze)
    stub_const('DATE_AFTER_PHASE_1', Date.new(2022, 02, 20).freeze)

    add_container_registries_and_project_statistics(proj11.id, 2, 'import_done', DATE_BEFORE_PHASE_1, namespace1.id)
    add_container_registries_and_project_statistics(proj12.id, 3, 'import_done', DATE_BEFORE_PHASE_1, namespace1.id)
    add_container_registries_and_project_statistics(proj21.id, 1, 'import_done', DATE_BEFORE_PHASE_1, namespace2.id)
    add_container_registries_and_project_statistics(proj22.id, 2, 'default', DATE_AFTER_PHASE_1, namespace2.id)
  end

  it 'backfills container_registry_size for unique project_ids', :aggregate_failures do
    batch_max_value = container_repositories_table.pluck(:project_id).max
    migration = described_class.new(start_id: 1, end_id: batch_max_value,
                    batch_table: 'container_repositories', batch_column: 'project_id',
                    sub_batch_size: 1_000, pause_ms: 0,
                    connection: ApplicationRecord.connection)

    allow(::Gitlab).to receive(:com?).and_return(true)
    allow(::ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(true)
    allow(::ContainerRegistry::GitlabApiClient).to receive(:deduplicated_size).and_return(3000)
    allow(::Namespaces::ScheduleAggregationWorker).to receive(:perform_async)

    migration.perform

    expect(project_statistics_table.where(container_registry_size: 0).count).to eq(0)
    expect(::Namespaces::ScheduleAggregationWorker).to have_received(:perform_async).exactly(4).times
    expect(::ContainerRegistry::GitlabApiClient).to have_received(:supports_gitlab_api?).exactly(4).times
  end

  private

  def add_container_registries_and_project_statistics(project_id, count, migration_state, created_at, namespace_id)
    project_statistics_table.create!(
      project_id: project_id,
      namespace_id: namespace_id
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
end
