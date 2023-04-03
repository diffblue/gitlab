# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillProjectStatisticsStorageSizeWithoutUploadsSize, :migration, schema: 20221104115712, feature_category: :consumables_cost_management do # rubocop:disable Layout/LineLength
  let!(:namespace) { table(:namespaces) }
  let!(:project_statistics_table) { table(:project_statistics) }
  let!(:project) { table(:projects) }
  let!(:count_of_colums) { ProjectStatistics::STORAGE_SIZE_COMPONENTS.count }

  let(:default_storage_size) { 12 }
  let(:default_uploads_size) { 5 }
  let(:default_stats) do
    {
      repository_size: 1,
      wiki_size: 1,
      lfs_objects_size: 1,
      build_artifacts_size: 1,
      packages_size: 1,
      snippets_size: 1,
      pipeline_artifacts_size: 1,
      uploads_size: default_uploads_size,
      storage_size: default_storage_size
    }
  end

  context 'with many project statistics records' do
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

    let!(:proj_namespace5) do
      namespace.create!(
        name: 'proj5', path: 'proj5', type: 'Project', parent_id: sub_group.id
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

    let!(:proj5) do
      project.create!(
        name: 'proj5', path: 'proj5', namespace_id: sub_group.id, project_namespace_id: proj_namespace5.id
      )
    end

    let(:migration) do
      described_class.new(start_id: 1, end_id: proj4.id,
                          batch_table: 'project_statistics', batch_column: 'project_id',
                          sub_batch_size: 1_000, pause_ms: 0,
                          connection: ApplicationRecord.connection)
    end

    describe '#filter_batch' do
      it 'filters out project_statistics out of scope' do
        project_statistics = generate_records
        project_statistics_table.create!(
          project_id: proj5.id,
          namespace_id: proj5.namespace_id,
          repository_size: 1,
          wiki_size: 1,
          lfs_objects_size: 1,
          build_artifacts_size: 1,
          packages_size: 1,
          snippets_size: 1,
          pipeline_artifacts_size: 1,
          uploads_size: 0,
          storage_size: 7
        )

        expected = project_statistics.map(&:id)
        actual = migration.filter_batch(project_statistics_table).pluck(:id)

        expect(actual).to match_array(expected)
      end
    end

    describe '#perform' do
      subject(:perform_migration) { migration.perform }

      context 'when project_statistics backfill runs' do
        before do
          generate_records
        end

        context 'when storage_size includes uploads_size' do
          it 'removes uploads_size from storage_size' do
            allow(::Namespaces::ScheduleAggregationWorker).to receive(:perform_async)
            expect(project_statistics_table.pluck(:storage_size).uniq).to match_array([default_storage_size])

            perform_migration

            expect(project_statistics_table.pluck(:storage_size).uniq).to match_array(
              [default_storage_size - default_uploads_size]
            )
            expect(::Namespaces::ScheduleAggregationWorker).to have_received(:perform_async).exactly(4).times
          end
        end

        context 'when storage_size does not include uploads_size' do
          it 'does not update the record' do
            allow(::Namespaces::ScheduleAggregationWorker).to receive(:perform_async)
            proj_stat = project_statistics_table.last
            expect(proj_stat.storage_size).to eq(default_storage_size)
            proj_stat.storage_size = default_storage_size - default_uploads_size
            proj_stat.save!

            perform_migration

            expect(project_statistics_table.pluck(:storage_size).uniq).to match_array(
              [default_storage_size - default_uploads_size]
            )
            expect(::Namespaces::ScheduleAggregationWorker).to have_received(:perform_async).exactly(3).times
          end
        end

        context 'when not checking the namespace plan' do
          it 'does not run' do
            allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)
            allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(false)
            allow(::Namespaces::ScheduleAggregationWorker).to receive(:perform_async)
            expect(project_statistics_table.pluck(:storage_size).uniq).to match_array([default_storage_size])

            perform_migration

            expect(project_statistics_table.pluck(:storage_size).uniq).to match_array([default_storage_size])
            expect(::Namespaces::ScheduleAggregationWorker).not_to have_received(:perform_async)
          end
        end
      end
    end
  end

  describe '#perform' do
    it 'coerces a null wiki_size to 0' do
      project_statistics = create_project_stats({ wiki_size: nil })
      allow(::Namespaces::ScheduleAggregationWorker).to receive(:perform_async)
      migration = create_migration(end_id: project_statistics.project_id)

      migration.perform

      project_statistics.reload
      expect(project_statistics.storage_size).to eq(6)
    end

    it 'coerces a null snippets_size to 0' do
      project_statistics = create_project_stats({ snippets_size: nil })
      allow(::Namespaces::ScheduleAggregationWorker).to receive(:perform_async)
      migration = create_migration(end_id: project_statistics.project_id)

      migration.perform

      project_statistics.reload
      expect(project_statistics.storage_size).to eq(6)
    end
  end

  private

  def create_project_stats(override_stats = {})
    stats = default_stats.merge(override_stats)

    group = namespace.create!(name: 'group_a', path: 'group-a', type: 'Group')
    project_namespace = namespace.create!(name: 'project_a', path: 'project_a', type: 'Project', parent_id: group.id)
    proj = project.create!(name: 'project_a', path: 'project-a', namespace_id: group.id,
                           project_namespace_id: project_namespace.id)
    project_statistics_table.create!(
      project_id: proj.id,
      namespace_id: group.id,
      **stats
    )
  end

  def create_migration(end_id:)
    described_class.new(start_id: 1, end_id: end_id,
                        batch_table: 'project_statistics', batch_column: 'project_id',
                        sub_batch_size: 1_000, pause_ms: 0,
                        connection: ApplicationRecord.connection)
  end

  def generate_records
    [proj1, proj2, proj3, proj4].map do |proj|
      project_statistics_table.create!(
        default_stats.merge({
                              project_id: proj.id,
                              namespace_id: proj.namespace_id
                            })
      )
    end
  end
end
