# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillProjectStatisticsStorageSizeWithRecentSize,
  schema: 20230823090001,
  feature_category: :consumables_cost_management do
  include MigrationHelpers::ProjectStatisticsHelper

  include_context 'when backfilling project statistics'

  let(:default_uploads_size) { 10.megabytes }
  let(:default_storage_size) { 10.megabytes }
  let(:recent_objects_size) { 5 }
  let(:default_stats) do
    {
      repository_size: 10,
      uploads_size: default_uploads_size,
      storage_size: default_storage_size,
      updated_at: Time.current - 1.year
    }
  end

  describe '#perform' do
    subject(:perform_migration) { migration.perform }

    context 'when project_statistics backfill runs' do
      before do
        generate_records(default_projects, project_statistics_table, default_stats)

        allow_next_instance_of(Repository) do |repo|
          allow(repo).to receive(:recent_objects_size).and_return(recent_objects_size)
        end
      end

      context 'when on should_check_namespace_plan? returns true' do
        before do
          allow(::Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(true)
        end

        it 'does not include uploads_size in the storage_size' do
          allow(::Namespaces::ScheduleAggregationWorker).to receive(:perform_async)
          expect(project_statistics_table.pluck(:storage_size).uniq).to match_array([default_storage_size])

          perform_migration

          expect(project_statistics_table.pluck(:storage_size).uniq).to match_array(
            [recent_objects_size.megabytes]
          )
          expect(::Namespaces::ScheduleAggregationWorker).to have_received(:perform_async).exactly(4).times
        end
      end

      context 'when on should_check_namespace_plan? returns false' do
        before do
          allow(::Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(false)
        end

        it 'includes uploads_size in the storage_size' do
          allow(::Namespaces::ScheduleAggregationWorker).to receive(:perform_async)
          expect(project_statistics_table.pluck(:storage_size).uniq).to match_array([default_storage_size])

          perform_migration

          expect(project_statistics_table.pluck(:storage_size).uniq).to match_array(
            [recent_objects_size.megabytes + default_uploads_size]
          )
          expect(::Namespaces::ScheduleAggregationWorker).to have_received(:perform_async).exactly(4).times
        end
      end
    end
  end
end
