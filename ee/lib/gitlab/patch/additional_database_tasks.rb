# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record/migration'

module Gitlab
  module Patch
    module AdditionalDatabaseTasks
      # Returns the proper path for the structure.sql and schema_cache.yml
      # files for additional databases.
      module ActiveRecordDatabaseTasksDumpFilename
        def schema_dump_path(db_config, format = ActiveRecord.schema_format)
          db_dir = Gitlab::Database.all_database_connections[db_config.name.to_s]&.db_dir
          return super if default_db_dir?(db_dir)

          Rails.root.join(db_dir, 'structure.sql').to_s
        end

        def cache_dump_filename(database, schema_cache_path: nil)
          db_dir = Gitlab::Database.all_database_connections[database]&.db_dir
          return super if default_db_dir?(db_dir)

          Rails.root.join(db_dir, 'schema_cache.yml').to_s
        end

        def default_db_dir?(db_dir)
          db_dir.nil? || db_dir == default_db_dir
        end

        def default_db_dir
          Rails.root.join('db')
        end
      end

      # We can set the migrations_paths in the database configurations to tell
      # Rails where the migrations for the additional database will live when
      # using the --database flag. We use this setting also to include the Geo
      # post-deployment migrations path.
      #
      # The problem is that the Rails migration generator joins the elements
      # within the array into one path while creating the migration file which
      # breaks both regular and post migrations for the Geo database because
      # the migration file will be written in the wrong place.
      #
      # This patch modifies ActiveRecord::Generators::Migration#configured_migrated_path
      # to exclude any post-migration path, and always return only one value
      # while creating a migration file.
      #
      # For more context:
      #   - https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/patch/database_config.rb#L14-L16
      #   - https://github.com/rails/rails/blob/v6.1.4.7/activerecord/lib/rails/generators/active_record/migration.rb#L42-L49
      #   - https://github.com/rails/rails/blob/v6.1.4.7/activerecord/lib/rails/generators/active_record/migration/migration_generator.rb#L17
      module ActiveRecordMigrationConfiguredMigratePath
        POST_MIGRATE_PATH_SUFFIX = '/post_migrate'

        def configured_migrate_path
          Array(super)
            .reject { |path| path.end_with?(POST_MIGRATE_PATH_SUFFIX) }
            .first
        end
      end

      def self.patch!
        ActiveRecord::Tasks::DatabaseTasks.singleton_class.prepend(ActiveRecordDatabaseTasksDumpFilename)
        ActiveRecord::Generators::Migration.prepend(ActiveRecordMigrationConfiguredMigratePath)
      end
    end
  end
end
