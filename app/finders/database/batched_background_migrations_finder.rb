# frozen_string_literal: true

module Database
  class BatchedBackgroundMigrationsFinder
    RETURNED_MIGRATIONS = 10

    def initialize(database:)
      @database = database
    end

    def execute
      Gitlab::Database::SharedModel.using_connection(connection) do
        batched_migration_class.ordered_by_created_at_desc.for_gitlab_schema(schema).limit(RETURNED_MIGRATIONS)
      end
    end

    private

    attr_accessor :database

    def connection
      @connection ||= Gitlab::Database.database_base_models[database].connection
    end

    def batched_migration_class
      Gitlab::Database::BackgroundMigration::BatchedMigration
    end

    def schema
      Gitlab::Database.gitlab_schemas_for_connection(connection)
    end
  end
end
