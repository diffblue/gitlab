# frozen_string_literal: true

class BackgroundMigrationsFinder
  attr_accessor :database

  def initialize(database:)
    @database = database
  end

  def execute
    Gitlab::Database::SharedModel.using_connection(base_model.connection) do
      Gitlab::Database::BackgroundMigration::BatchedMigration.all
    end
  end

  private

  def base_model
    Gitlab::Database.database_base_models[database]
  end
end
