# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::BatchedBackgroundMigrationWorker do
  it_behaves_like 'it runs batched background migration jobs', :main, feature_flag: :execute_batched_migrations_on_schedule

  describe 'full integration test', :freeze_time do
    include Gitlab::Database::DynamicModelHelpers

    class Gitlab::BackgroundMigration::ExampleDataMigration < Gitlab::BackgroundMigration::BaseJob
      include Gitlab::Database::DynamicModelHelpers

      def perform(start_id, end_id, batch_table, batch_column, sub_batch_size, pause_ms)
        rel = define_batchable_model(:example_data, connection: connection)

        rel.each_batch(column: batch_column, of: sub_batch_size) do |sub_batch|
          sub_batch.update_all(some_column: 0)
        end
      end
    end

    let!(:migration) do
      create(
        :batched_background_migration,
        :active,
        table_name: table_name,
        column_name: :id,
        batch_size: batch_size,
        sub_batch_size: sub_batch_size,
        job_class_name: 'ExampleDataMigration',
        job_arguments: []
      )
    end

    let(:table_name) { 'example_data' }
    let(:batch_size) { 5 }
    let(:sub_batch_size) { 2 }
    let(:total_size) { batch_size * 10 }
    let(:number_of_batches) { (total_size / batch_size).ceil }

    let(:connection) { Gitlab::Database.database_base_models[described_class.tracking_database].connection }

    before do
      # create example table to migrate
      connection.execute(<<~SQL)
        CREATE TABLE #{table_name} (id serial primary key, some_column integer);
        INSERT INTO #{table_name} (some_column) SELECT generate_series(1,#{total_size});
      SQL

      stub_feature_flags(execute_batched_migrations_on_schedule: true)
    end

    subject do
      number_of_batches.times do
        described_class.new.perform

        travel_to((migration.interval + described_class::INTERVAL_VARIANCE).seconds.from_now)
      end
    end

    it 'executes the migration and marks it done after updating all batches' do
      expect { subject }.to change { migration.reload.status }.from(1).to(3) # active -> finished
    end

    it 'changes all records' do
      rel = define_batchable_model(:example_data, connection: connection)

      expect { subject }.to change { rel.where('some_column <> 0').count }.from(total_size).to(0)
    end
  end
end
