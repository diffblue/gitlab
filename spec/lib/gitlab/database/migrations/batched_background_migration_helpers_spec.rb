# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::BatchedBackgroundMigrationHelpers do
  let(:migration) do
    ActiveRecord::Migration.new.extend(described_class).extend(Gitlab::Database::Migrations::ReestablishedConnectionStack)
  end

  describe '#queue_batched_background_migration' do
    let(:pgclass_info) { instance_double('Gitlab::Database::PgClass', cardinality_estimate: 42) }

    before do
      allow(Gitlab::Database::PgClass).to receive(:for_table).and_call_original
      expect(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:require_dml_mode!)

      allow(migration).to receive(:transaction_open?).and_return(false)
    end

    context 'when such migration already exists' do
      it 'does not create duplicate migration' do
        create(
          :batched_background_migration,
          job_class_name: 'MyJobClass',
          table_name: :projects,
          column_name: :id,
          interval: 10.minutes,
          min_value: 5,
          max_value: 1005,
          batch_class_name: 'MyBatchClass',
          batch_size: 200,
          sub_batch_size: 20,
          job_arguments: [[:id], [:id_convert_to_bigint]],
          gitlab_schema: :gitlab_ci
        )

        expect do
          migration.queue_batched_background_migration(
            'MyJobClass',
            :projects,
            :id,
            [:id], [:id_convert_to_bigint],
            job_interval: 5.minutes,
            batch_min_value: 5,
            batch_max_value: 1000,
            batch_class_name: 'MyBatchClass',
            batch_size: 100,
            sub_batch_size: 10,
            gitlab_schema: :gitlab_ci)
        end.not_to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }
      end
    end

    it 'creates the database record for the migration' do
      expect(Gitlab::Database::PgClass).to receive(:for_table).with(:projects).and_return(pgclass_info)

      expect do
        migration.queue_batched_background_migration(
          'MyJobClass',
          :projects,
          :id,
          job_interval: 5.minutes,
          batch_min_value: 5,
          batch_max_value: 1000,
          batch_class_name: 'MyBatchClass',
          batch_size: 100,
          max_batch_size: 10000,
          sub_batch_size: 10,
          gitlab_schema: :gitlab_ci)
      end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

      expect(Gitlab::Database::BackgroundMigration::BatchedMigration.last).to have_attributes(
        job_class_name: 'MyJobClass',
        table_name: 'projects',
        column_name: 'id',
        interval: 300,
        min_value: 5,
        max_value: 1000,
        batch_class_name: 'MyBatchClass',
        batch_size: 100,
        max_batch_size: 10000,
        sub_batch_size: 10,
        job_arguments: %w[],
        status_name: :active,
        total_tuple_count: pgclass_info.cardinality_estimate,
        gitlab_schema: 'gitlab_ci')
    end

    context 'when the job interval is lower than the minimum' do
      let(:minimum_delay) { described_class::BATCH_MIN_DELAY }

      it 'sets the job interval to the minimum value' do
        expect do
          migration.queue_batched_background_migration('MyJobClass', :events, :id, job_interval: minimum_delay - 1.minute)
        end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

        created_migration = Gitlab::Database::BackgroundMigration::BatchedMigration.last

        expect(created_migration.interval).to eq(minimum_delay)
      end
    end

    context 'when additional arguments are passed to the method' do
      it 'saves the arguments on the database record' do
        expect do
          migration.queue_batched_background_migration(
            'MyJobClass',
            :projects,
            :id,
            'my',
            'arguments',
            job_interval: 5.minutes,
            batch_max_value: 1000)
        end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

        expect(Gitlab::Database::BackgroundMigration::BatchedMigration.last).to have_attributes(
          job_class_name: 'MyJobClass',
          table_name: 'projects',
          column_name: 'id',
          interval: 300,
          min_value: 1,
          max_value: 1000,
          job_arguments: %w[my arguments])
      end
    end

    context 'when the max_value is not given' do
      context 'when records exist in the database' do
        let!(:event1) { create(:event) }
        let!(:event2) { create(:event) }
        let!(:event3) { create(:event) }

        it 'creates the record with the current max value' do
          expect do
            migration.queue_batched_background_migration('MyJobClass', :events, :id, job_interval: 5.minutes)
          end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

          created_migration = Gitlab::Database::BackgroundMigration::BatchedMigration.last

          expect(created_migration.max_value).to eq(event3.id)
        end

        it 'creates the record with an active status' do
          expect do
            migration.queue_batched_background_migration('MyJobClass', :events, :id, job_interval: 5.minutes)
          end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

          expect(Gitlab::Database::BackgroundMigration::BatchedMigration.last).to be_active
        end
      end

      context 'when the database is empty' do
        it 'sets the max value to the min value' do
          expect do
            migration.queue_batched_background_migration('MyJobClass', :events, :id, job_interval: 5.minutes)
          end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

          created_migration = Gitlab::Database::BackgroundMigration::BatchedMigration.last

          expect(created_migration.max_value).to eq(created_migration.min_value)
        end

        it 'creates the record with a finished status' do
          expect do
            migration.queue_batched_background_migration('MyJobClass', :projects, :id, job_interval: 5.minutes)
          end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

          expect(Gitlab::Database::BackgroundMigration::BatchedMigration.last).to be_finished
        end

        context 'when within transaction' do
          before do
            allow(migration).to receive(:transaction_open?).and_return(true)
          end

          it 'does raise an exception' do
            expect { migration.queue_batched_background_migration('MyJobClass', :events, :id, job_interval: 5.minutes)}
              .to raise_error /`queue_batched_background_migration` cannot be run inside a transaction./
          end
        end
      end
    end

    context 'when gitlab_schema is not given' do
      it 'fetches gitlab_schema from the migration context' do
        expect(migration).to receive(:gitlab_schema_from_context).and_return(:gitlab_ci)

        expect do
          migration.queue_batched_background_migration('MyJobClass', :events, :id, job_interval: 5.minutes)
        end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

        created_migration = Gitlab::Database::BackgroundMigration::BatchedMigration.last

        expect(created_migration.gitlab_schema).to eq('gitlab_ci')
      end
    end
  end

  describe '#finalize_batched_background_migration' do
    let!(:batched_migration) { create(:batched_background_migration, job_class_name: 'MyClass', table_name: :projects, column_name: :id, job_arguments: []) }

    before do
      expect(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:require_dml_mode!)

      allow(migration).to receive(:transaction_open?).and_return(false)
    end

    it 'finalizes the migration' do
      allow_next_instance_of(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner) do |runner|
        expect(runner).to receive(:finalize).with('MyClass', :projects, :id, [])
      end

      migration.finalize_batched_background_migration(job_class_name: 'MyClass', table_name: :projects, column_name: :id, job_arguments: [])
    end

    context 'when the migration does not exist' do
      it 'raises an exception' do
        expect do
          migration.finalize_batched_background_migration(job_class_name: 'MyJobClass', table_name: :projects, column_name: :id, job_arguments: [])
        end.to raise_error(RuntimeError, 'Could not find batched background migration')
      end
    end

    context 'when within transaction' do
      before do
        allow(migration).to receive(:transaction_open?).and_return(true)
      end

      it 'does raise an exception' do
        expect { migration.finalize_batched_background_migration(job_class_name: 'MyJobClass', table_name: :projects, column_name: :id, job_arguments: []) }
          .to raise_error /`finalize_batched_background_migration` cannot be run inside a transaction./
      end
    end

    context 'when multiple database is enabled' do
      let(:migration_wrapper) do
        Gitlab::Database::BackgroundMigration::BatchedMigrationWrapper.new(connection: connection)
      end

      let(:migration_helpers) { ActiveRecord::Migration.new }
      let(:table_name) { :_test_batched_migrations_test_table }
      let(:column_name) { :some_id }
      let(:job_arguments) { [:some_id, :some_id_convert_to_bigint] }

      let(:migration_status) { :active }

      context 'when the migration is not yet completed', :reestablished_active_record_base do
        # let(:batched_migration) do
        #   create(:batched_background_migration, migration_status, max_value: 8, batch_size: 2, sub_batch_size: 1, interval: 0, table_name: table_name, column_name: column_name, job_arguments: job_arguments, pause_ms: 0, gitlab_schema: 'gitlab_ci')
        # end

        before do
          skip_if_multiple_databases_not_setup

          ActiveRecord::Base.establish_connection(:ci)

          migration_helpers.drop_table table_name, if_exists: true
          migration_helpers.create_table table_name, id: false do |t|
            t.integer :some_id, primary_key: true
            t.integer :some_id_convert_to_bigint
          end

          migration_helpers.execute("INSERT INTO #{table_name} VALUES (1, 1), (2, 2), (3, NULL), (4, NULL), (5, NULL), (6, NULL), (7, NULL), (8, NULL)")

          # common_attributes = {
          #   batched_migration: batched_migration,
          #   batch_size: 2,
          #   sub_batch_size: 1,
          #   pause_ms: 0
          # }

          expect(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:require_dml_mode!)

          allow(described_class).to receive(:gitlab_schema_from_context).and_return(:ci)
        end

        after do
          migration_helpers.drop_table table_name, if_exists: true
        end

        it 'completes the migration' do
          base_model = Gitlab::Database.database_base_models.fetch(:ci)

          Gitlab::Database::SharedModel.using_connection(base_model.connection) do
            batched_migration = create(:batched_background_migration, migration_status, max_value: 8, batch_size: 2, sub_batch_size: 1, interval: 0, table_name: table_name, column_name: column_name, job_arguments: job_arguments, pause_ms: 0, gitlab_schema: 'gitlab_ci')

            common_attributes = {
              batched_migration: batched_migration,
              batch_size: 2,
              sub_batch_size: 1,
              pause_ms: 0
            }

            create(:batched_background_migration_job, :succeeded, common_attributes.merge(min_value: 1, max_value: 2))
            create(:batched_background_migration_job, :pending, common_attributes.merge(min_value: 3, max_value: 4))
            create(:batched_background_migration_job, :failed, common_attributes.merge(min_value: 5, max_value: 6, attempts: 1))
          end


          migration.finalize_batched_background_migration(job_class_name: 'CopyColumnUsingBackgroundMigrationJob', table_name: table_name, column_name: column_name, job_arguments: job_arguments)

          expect(Gitlab::Database::BackgroundMigration::BatchedMigration).to receive(:find_for_configuration).twice
            .with(:gitlab_ci, 'CopyColumnUsingBackgroundMigrationJob', table_name, column_name, job_arguments)
            .and_return(batched_migration)

          expect(batched_migration).to receive(:finalize!).and_call_original

          expect do
            migration.finalize_batched_background_migration(job_class_name: batched_migration.job_class_name, table_name: table_name, column_name: column_name, job_arguments: job_arguments)
          end.to change { batched_migration.reload.status_name }.from(:active).to(:finished)

          expect(batched_migration.batched_jobs).to all(be_succeeded)

          not_converted = migration_helpers.execute("SELECT * FROM #{table_name} WHERE some_id_convert_to_bigint IS NULL")
          expect(not_converted.to_a).to be_empty
        end
      end
    end

    context 'when within transaction' do
      before do
        allow(migration).to receive(:transaction_open?).and_return(true)
      end

      it 'does raise an exception' do
        expect { migration.finalize_batched_background_migration(job_class_name: 'MyJobClass', table_name: :projects, column_name: :id, job_arguments: []) }
          .to raise_error /`finalize_batched_background_migration` cannot be run inside a transaction./
      end
    end
  end

  describe '#delete_batched_background_migration' do
    before do
      expect(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:require_dml_mode!)
    end

    context 'when migration exists' do
      it 'deletes it' do
        create(
          :batched_background_migration,
          job_class_name: 'MyJobClass',
          table_name: :projects,
          column_name: :id,
          interval: 10.minutes,
          min_value: 5,
          max_value: 1005,
          batch_class_name: 'MyBatchClass',
          batch_size: 200,
          sub_batch_size: 20,
          job_arguments: [[:id], [:id_convert_to_bigint]]
        )

        expect do
          migration.delete_batched_background_migration(
            'MyJobClass',
            :projects,
            :id,
            [[:id], [:id_convert_to_bigint]])
        end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.from(1).to(0)
      end
    end

    context 'when migration does not exist' do
      it 'does nothing' do
        create(
          :batched_background_migration,
          job_class_name: 'SomeOtherJobClass',
          table_name: :projects,
          column_name: :id,
          interval: 10.minutes,
          min_value: 5,
          max_value: 1005,
          batch_class_name: 'MyBatchClass',
          batch_size: 200,
          sub_batch_size: 20,
          job_arguments: [[:id], [:id_convert_to_bigint]]
        )

        expect do
          migration.delete_batched_background_migration(
            'MyJobClass',
            :projects,
            :id,
            [[:id], [:id_convert_to_bigint]])
        end.not_to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }
      end
    end
  end

  describe '#gitlab_schema_from_context' do
    context 'when allowed_gitlab_schemas is not available' do
      it 'defaults to :gitlab_main' do
        expect(migration.gitlab_schema_from_context).to eq(:gitlab_main)
      end
    end

    context 'when allowed_gitlab_schemas is available' do
      it 'uses schema from allowed_gitlab_schema' do
        expect(migration).to receive(:allowed_gitlab_schemas).and_return([:gitlab_ci])

        expect(migration.gitlab_schema_from_context).to eq(:gitlab_ci)
      end
    end
  end
end
