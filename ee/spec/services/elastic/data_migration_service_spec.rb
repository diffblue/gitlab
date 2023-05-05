# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::DataMigrationService, :elastic, :clean_gitlab_redis_shared_state, feature_category: :global_search do
  subject { described_class }

  describe '.migrations' do
    it 'all migration names are unique' do
      expect(subject.migrations.count).to eq(subject.migrations.map(&:name).uniq.count)
    end

    context 'migration_files stubbed' do
      let(:migration_files) { %w(ee/elastic/migrate/20201105180000_example_migration.rb ee/elastic/migrate/20201201130000_example_migration.rb) }

      before do
        allow(subject).to receive(:migration_files).and_return(migration_files)
      end

      it 'creates migration records' do
        migrations = subject.migrations
        migration = migrations.first

        expect(migrations.count).to eq(2)
        expect(migration.version).to eq(20201105180000)
        expect(migration.name).to eq('ExampleMigration')
        expect(migration.filename).to eq(migration_files.first)
      end
    end

    context 'migrations in optimized order for each index' do
      it 'ensure all update migrations run before backfill migrations' do
        error_message = <<~DOC
          Migrations should be ordered so all migrations that use ::Elastic::MigrationUpdateMappingsHelper
          run before any migrations that use ::Elastic::MigrationUpdateMappingsHelper. If this spec fails, rename the
          `YYYYMMDDHHMMSS` part of the migration filename with a datetime before the last backfill migration for the
          index_name.
          Ref: https://docs.gitlab.com/ee/development/search/advanced_search_migration_styleguide.html#best-practices-for-advanced-search-migrations
        DOC

        migrations = subject.migrations.map { |m| m.send(:migration) }

        filtered_migrations = migrations.filter do |m|
          klass = m.class
          klass.include?(::Elastic::MigrationUpdateMappingsHelper) || klass.include?(::Elastic::MigrationUpdateMappingsHelper)
        end

        migrations_grouped_by_index = filtered_migrations.group_by { |m| m.send(:index_name) }

        migrations_grouped_by_index.each do |index_name, migrations|
          backfill_versions = migrations.filter do |m|
            m.class.include?(::Elastic::MigrationBackfillHelper)
          end.map(&:version)

          mapping_versions = migrations.filter do |m|
            m.class.include?(::Elastic::MigrationUpdateMappingsHelper)
          end.map(&:version)

          backfill_ranges = backfill_versions.each_cons(2).map { |a, b| a..b }
          result = mapping_versions.select { |v| backfill_ranges.any? { |r| r.include?(v) } }
          expect(result).to be_empty, "index: #{index_name} - #{error_message}"
        end
      end
    end
  end

  describe '.migration_has_finished_uncached?' do
    let(:migration) { subject.migrations.first }
    let(:migration_name) { migration.name.underscore }

    it 'returns true if migration has finished' do
      expect(subject.migration_has_finished_uncached?(migration_name)).to eq(true)

      migration.save!(completed: false)
      refresh_index!

      expect(subject.migration_has_finished_uncached?(migration_name)).to eq(false)

      migration.save!(completed: true)
      refresh_index!

      expect(subject.migration_has_finished_uncached?(migration_name)).to eq(true)
    end
  end

  describe '.migration_has_finished?' do
    let(:migration) { subject.migrations.first }
    let(:migration_name) { migration.name.underscore }
    let(:finished) { true }

    before do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      allow(subject).to receive(:migration_has_finished_uncached?).with(migration_name).and_return(finished)
    end

    it 'calls the uncached method only once' do
      expect(subject).to receive(:migration_has_finished_uncached?).once

      expect(subject.migration_has_finished?(migration_name)).to eq(finished)
      expect(subject.migration_has_finished?(migration_name)).to eq(finished)
    end
  end

  describe '.mark_all_as_completed!' do
    before do
      # Clear out the migrations index since it is setup initially with
      # everything finished migrating
      es_helper.delete_migrations_index
      es_helper.create_migrations_index
    end

    it 'creates all migration versions' do
      expect(Elastic::MigrationRecord.load_versions(completed: true).count).to eq(0)

      subject.mark_all_as_completed!
      refresh_index!

      expect(Elastic::MigrationRecord.load_versions(completed: true).count).to eq(subject.migrations.count)
    end

    it 'drops all cache keys' do
      allow(subject).to receive(:migrations).and_return(
        [
          Elastic::MigrationRecord.new(version: 100, name: 'SomeMigration', filename: nil),
          Elastic::MigrationRecord.new(version: 200, name: 'SomeOtherMigration', filename: nil)
        ]
      )

      subject.migrations.each do |migration|
        expect(subject).to receive(:drop_migration_has_finished_cache!).with(migration)
      end

      subject.mark_all_as_completed!
    end
  end

  describe '.drop_migration_has_finished_cache!' do
    let(:migration) { subject.migrations.first }
    let(:migration_name) { migration.name.underscore }
    let(:finished) { true }

    before do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      allow(subject).to receive(:migration_has_finished_uncached?).with(migration_name).and_return(finished)
    end

    it 'drops cache' do
      expect(subject).to receive(:migration_has_finished_uncached?).twice

      expect(subject.migration_has_finished?(migration_name)).to eq(finished)

      subject.drop_migration_has_finished_cache!(migration)

      expect(subject.migration_has_finished?(migration_name)).to eq(finished)
    end
  end

  describe '.migration_halted?' do
    let(:migration) { subject.migrations.last }

    before do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      allow(subject).to receive(:migration_halted_uncached?).with(migration).and_return(true, false)
    end

    it 'calls the uncached method only once' do
      expect(subject).to receive(:migration_halted_uncached?).once

      expect(subject.migration_halted?(migration)).to eq(true)
      expect(subject.migration_halted?(migration)).to eq(true)
    end
  end

  describe '.migration_halted_uncached?' do
    let(:migration) { subject.migrations.last }
    let(:halted_response) { { '_source': { 'state': { halted: true } } }.with_indifferent_access }
    let(:not_halted_response) { { '_source': { 'state': { halted: false } } }.with_indifferent_access }

    it 'returns true if migration has been halted' do
      allow(migration).to receive(:load_from_index).and_return(not_halted_response)
      expect(subject.migration_halted_uncached?(migration)).to eq(false)

      allow(migration).to receive(:load_from_index).and_return(halted_response)
      expect(subject.migration_halted_uncached?(migration)).to eq(true)
    end
  end

  describe '.drop_migration_halted_cache!' do
    let(:migration) { subject.migrations.last }

    before do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      allow(subject).to receive(:migration_halted_uncached?).with(migration).and_return(true, false)
    end

    it 'drops cache' do
      expect(subject).to receive(:migration_halted_uncached?).twice

      expect(subject.migration_halted?(migration)).to eq(true)

      subject.drop_migration_halted_cache!(migration)

      expect(subject.migration_halted?(migration)).to eq(false)
    end
  end

  describe '.halted_migration' do
    let(:migration) { subject.migrations.last }
    let(:halted_response) { { '_source': { 'state': { halted: true } } }.with_indifferent_access }

    before do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      allow(Elastic::MigrationRecord).to receive(:new).and_call_original
      allow(Elastic::MigrationRecord).to receive(:new).with(version: migration.version, name: migration.name, filename: migration.filename).and_return(migration)
    end

    it 'returns a migration when it is halted' do
      expect(subject.halted_migration).to be_nil

      allow(migration).to receive(:load_from_index).and_return(halted_response)
      subject.drop_migration_halted_cache!(migration)

      expect(subject.halted_migration).to eq(migration)
    end
  end

  describe 'pending_migrations?' do
    context 'when there is a pending migration' do
      let(:migration) { subject.migrations.first }

      before do
        migration.save!(completed: false)
      end

      after do
        Elastic::DataMigrationService.mark_all_as_completed! # rubocop: disable RSpec/DescribedClass
      end

      it 'returns true' do
        expect(subject.pending_migrations?).to eq(true)
      end
    end

    context 'when there is no pending migration' do
      it 'returns false' do
        expect(subject.pending_migrations?).to eq(false)
      end
    end
  end

  describe 'pending_migrations' do
    let(:pending_migration1) { subject.migrations[1] }
    let(:pending_migration2) { subject.migrations[2] }

    before do
      pending_migration1.save!(completed: false)
      pending_migration2.save!(completed: false)
    end

    after do
      Elastic::DataMigrationService.mark_all_as_completed! # rubocop: disable RSpec/DescribedClass
    end

    it 'returns only pending migrations' do
      expect(subject.pending_migrations.map(&:name)).to eq([pending_migration1, pending_migration2].map(&:name))
    end
  end
end
