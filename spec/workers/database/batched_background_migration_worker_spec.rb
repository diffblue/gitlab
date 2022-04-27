# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::BatchedBackgroundMigrationWorker do
  it_behaves_like 'it runs batched background migration jobs', :main, feature_flag: :execute_batched_migrations_on_schedule

  describe 'executing an entire migration', :freeze_time do
    include Gitlab::Database::DynamicModelHelpers

    let(:migration_class) do
      Class.new(Gitlab::BackgroundMigration::BatchedMigrationJob) do
        def perform
          each_sub_batch(
            operation_name: :update_all,
            batching_scope: -> (relation) { relation.where(status: 1) }
          ) do |sub_batch|
            sub_batch.update_all(some_column: 0)
          end
        end
      end
    end

    let!(:migration) do
      create(
        :batched_background_migration,
        :active,
        table_name: table_name,
        column_name: :id,
        max_value: total_size,
        batch_size: batch_size,
        sub_batch_size: sub_batch_size,
        job_class_name: 'ExampleDataMigration',
        job_arguments: []
      )
    end

    let(:table_name) { 'example_data' }
    let(:batch_size) { 5 }
    let(:sub_batch_size) { 2 }
    let(:number_of_batches) { 10 }
    let(:total_size) { batch_size * number_of_batches }

    let(:connection) { Gitlab::Database.database_base_models[described_class.tracking_database].connection }

    before do
      # create example table to migrate
      connection.execute(<<~SQL)
        CREATE TABLE #{table_name} (
          id integer primary key,
          some_column integer,
          status smallint);

        INSERT INTO #{table_name} (id, some_column, status)
        SELECT generate_series, generate_series, 1
        FROM generate_series(1, #{total_size});

        UPDATE #{table_name}
          SET status = 0
        WHERE some_column = #{total_size - 1};
      SQL

      stub_feature_flags(execute_batched_migrations_on_schedule: true)

      stub_const('Gitlab::BackgroundMigration::ExampleDataMigration', migration_class)
    end

    subject(:full_migration_run) do
      # process all batches, then do an extra execution to mark the job as finished
      (number_of_batches + 1).times do
        described_class.new.perform

        travel_to((migration.interval + described_class::INTERVAL_VARIANCE).seconds.from_now)
      end
    end

    it 'marks the migration record as finished' do
      expect { full_migration_run }.to change { migration.reload.status }.from(1).to(3) # active -> finished
    end

    it 'creates job records for each processed batch', :aggregate_failures do
      expect { full_migration_run }.to change { migration.reload.batched_jobs.count }.from(0)

      final_min_value = migration.batched_jobs.reduce(1) do |next_min_value, batched_job|
        expect(batched_job.min_value).to eq(next_min_value)

        batched_job.max_value + 1
      end

      final_max_value = final_min_value - 1
      expect(final_max_value).to eq(total_size)
    end

    it 'marks all job records as succeeded', :aggregate_failures do
      expect { full_migration_run }.to change { migration.reload.batched_jobs.count }.from(0)

      expect(migration.batched_jobs).to all(be_succeeded)
    end

    it 'changes matching records' do
      relation = define_batchable_model(:example_data, connection: connection)
        .where('status = 1 AND some_column <> 0')

      expect { full_migration_run }.to change { relation.count }.from(total_size - 1).to(0)
    end

    it 'does not change non-matching records' do
       relation = define_batchable_model(:example_data, connection: connection)
         .where('status <> 1 AND some_column <> 0')

       expect { full_migration_run }.not_to change { relation.count }
    end
  end
end
