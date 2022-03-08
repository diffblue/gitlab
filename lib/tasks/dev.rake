# frozen_string_literal: true

task dev: ["dev:setup"]

namespace :dev do
  desc "GitLab | Dev | Setup developer environment (db, fixtures)"
  task setup: :environment do
    ENV['force'] = 'yes'
    Rake::Task["gitlab:setup"].invoke

    Gitlab::Database::EachDatabase.each_database_connection do |connection|
      # Make sure DB statistics are up to date.
      connection.execute('ANALYZE')
    end

    Rake::Task["gitlab:shell:setup"].invoke
  end

  desc "GitLab | Dev | Eager load application"
  task load: :environment do
    Rails.configuration.eager_load = true
    Rails.application.eager_load!
  end

  databases = ActiveRecord::Tasks::DatabaseTasks.setup_initial_database_yaml

  namespace :copy_db do
    ActiveRecord::Tasks::DatabaseTasks.for_each(databases) do |name|
      next if name == 'main'

      desc "Copies the #{name} database from the main database"
      task name => :environment do
        db_config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: name)

        ApplicationRecord.connection.create_database(db_config.database, template: ApplicationRecord.connection_db_config.database)
      rescue ActiveRecord::DatabaseAlreadyExists
        warn "Database '#{db_config.database}' already exists"
      end
    end
  end
end
