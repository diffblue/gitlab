# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Patch::GeoDatabaseTasks do
  describe Gitlab::Patch::GeoDatabaseTasks::ActiveRecordDatabaseTasksDumpFilename do
    subject do
      Class.new do
        prepend Gitlab::Patch::GeoDatabaseTasks::ActiveRecordDatabaseTasksDumpFilename

        def dump_filename(db_config_name, format = ApplicationRecord.schema_format)
          'foo.sql'
        end

        def cache_dump_filename(db_config_name, format = ApplicationRecord.schema_format)
          'bar.yml'
        end
      end.new
    end

    describe '#dump_filename' do
      context 'with geo database config name' do
        it 'returns the path for the structure.sql file in the Geo database dir' do
          expect(subject.dump_filename(:geo)).to eq Rails.root.join('ee/db/geo/structure.sql').to_s
        end
      end

      context 'with other database config name' do
        it 'calls super' do
          expect(subject.dump_filename(:main)).to eq 'foo.sql'
        end
      end
    end

    describe '#cache_dump_filename' do
      context 'with geo database config name' do
        it 'returns the path for the schema_cache file in the Geo database dir' do
          expect(subject.cache_dump_filename(:geo)).to eq Rails.root.join('ee/db/geo/schema_cache.yml').to_s
        end
      end

      context 'with other database config name' do
        it 'calls super' do
          expect(subject.cache_dump_filename(:main)).to eq 'bar.yml'
        end
      end
    end
  end

  describe Gitlab::Patch::GeoDatabaseTasks::ActiveRecordMigrationConfiguredMigratePath do
    describe '#configured_migrate_path' do
      context 'when super returns nil' do
        subject do
          Class.new do
            prepend Gitlab::Patch::GeoDatabaseTasks::ActiveRecordMigrationConfiguredMigratePath

            def configured_migrate_path
              nil
            end
          end.new
        end

        it 'returns nil' do
          expect(subject.configured_migrate_path).to be_nil
        end
      end

      context 'when super returns only one regular migration path' do
        subject do
          Class.new do
            prepend Gitlab::Patch::GeoDatabaseTasks::ActiveRecordMigrationConfiguredMigratePath

            def configured_migrate_path
              'ee/db/geo/migrate'
            end
          end.new
        end

        it 'returns the configured migrate path' do
          expect(subject.configured_migrate_path).to eq('ee/db/geo/migrate')
        end
      end

      context 'when super returns only one post migrations path' do
        subject do
          Class.new do
            prepend Gitlab::Patch::GeoDatabaseTasks::ActiveRecordMigrationConfiguredMigratePath

            def configured_migrate_path
              'ee/db/geo/post_migrate'
            end
          end.new
        end

        it 'returns nil' do
          expect(subject.configured_migrate_path).to be_nil
        end
      end

      context 'when super does not include a post migrations path' do
        subject do
          Class.new do
            prepend Gitlab::Patch::GeoDatabaseTasks::ActiveRecordMigrationConfiguredMigratePath

            def configured_migrate_path
              'ee/db/geo/migrate'
            end
          end.new
        end

        it 'returns the configured migrations path' do
          expect(subject.configured_migrate_path).to eq('ee/db/geo/migrate')
        end
      end

      context 'when super includes a post migrations path' do
        subject do
          Class.new do
            prepend Gitlab::Patch::GeoDatabaseTasks::ActiveRecordMigrationConfiguredMigratePath

            def configured_migrate_path
              ['ee/db/geo/migrate', 'ee/db/geo/post_migrate']
            end
          end.new
        end

        it 'returns the regular migration path' do
          expect(subject.configured_migrate_path).to eq('ee/db/geo/migrate')
        end
      end
    end
  end
end
