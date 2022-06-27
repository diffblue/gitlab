# frozen_string_literal: true

class Database::BatchedBackgroundMigrationsFinder
  attr_accessor :database, :job_class_name, :include_started

  PAGE_SIZE = 10

  def initialize(database, job_class_name: nil, include_started: true)
    @database = database
    @job_class_name = job_class_name
    @include_started = include_started
  end

  def execute
    batched_background_migrations = Gitlab::Database::SharedModel.using_connection(base_model.connection) do
      Gitlab::Database::BackgroundMigration::BatchedMigration.list_order
    end

    # Locating the active migration job
    # to return all the records, including that migration if it exists
    active_migration = batched_background_migrations.active.first

    if active_migration
      batched_background_migrations.where("id >= ?", active_migration.id) # rubocop:disable CodeReuse/ActiveRecord
    else
      batched_background_migrations.limit(PAGE_SIZE)
    end
  end

  private

  def base_model
    Gitlab::Database.database_base_models[database]
  end
end
