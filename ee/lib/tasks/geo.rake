# frozen_string_literal: true

task spec: ['db:test:prepare:geo']

databases = ActiveRecord::Tasks::DatabaseTasks.setup_initial_database_yaml

# These db:* tasks are taken from Rails 7.0 since Rails 6.1 does not have
# built-in support for multiple databases for them. To be removed when we
# migrate to Rails 7.0:
# https://gitlab.com/gitlab-org/gitlab/-/issues/352190
#
# https://github.com/rails/rails/blob/main/activerecord/lib/active_record/railties/databases.rake
db_namespace = namespace :db do
  namespace :reset do
    task all: ["db:drop", "db:setup"]

    ActiveRecord::Tasks::DatabaseTasks.for_each(databases) do |name|
      desc "Drops and recreates the #{name} database from its schema for the current environment and loads the seeds."
      task name => ["db:drop:#{name}", "db:setup:#{name}"]
    end
  end

  namespace :setup do
    task all: ["db:create", :environment, "db:schema:load", :seed]

    ActiveRecord::Tasks::DatabaseTasks.for_each(databases) do |name|
      desc "Creates the #{name} database, loads the schema, and initializes with the seed data (use db:reset:#{name} to also drop the database first)"
      task name => ["db:create:#{name}", :environment, "db:schema:load:#{name}", "db:seed"]
    end
  end

  namespace :version do
    ActiveRecord::Tasks::DatabaseTasks.for_each(databases) do |name|
      desc "Retrieves the current #{name} database schema version number"
      task name => :load_config do
        original_db_config = ActiveRecord::Base.connection_db_config
        db_config = ActiveRecord::Base.configurations.configs_for(env_name: ActiveRecord::Tasks::DatabaseTasks.env, name: name)
        ActiveRecord::Base.establish_connection(db_config) # rubocop: disable Database/EstablishConnection
        puts "Current version: #{ActiveRecord::Base.connection.migration_context.current_version}"
      ensure
        ActiveRecord::Base.establish_connection(original_db_config) if original_db_config # rubocop: disable Database/EstablishConnection
      end
    end
  end

  namespace :seed do
    seed_loader = Class.new do
      def self.load_seed
        load('ee/db/geo/seeds.rb')
      end
    end

    desc "Loads the seed data from ee/db/geo/seeds.rb"
    task geo: :load_config do
      db_namespace["abort_if_pending_migrations"].invoke
      ActiveRecord::Tasks::DatabaseTasks.seed_loader = seed_loader
      ActiveRecord::Tasks::DatabaseTasks.load_seed
    end
  end
end

namespace :geo do
  GEO_LICENSE_ERROR_TEXT = 'GitLab Geo is not supported with this license. Please contact the sales team: https://about.gitlab.com/sales.'

  def log_deprecated_message(deprecated_task, task_to_invoke)
    puts "DEPRECATION WARNING: Using `bin/rails #{deprecated_task}` is deprecated and will be removed in Gitlab 15.0. Please run `bin/rails #{task_to_invoke}` instead.".color(:red)
  end

  namespace :db do |ns|
    desc 'GitLab | Geo | DB | Drops the Geo tracking database from config/database_geo.yml for the current RAILS_ENV.'
    task drop: [:environment] do
      Rake::Task['db:drop:geo'].invoke

      log_deprecated_message('geo:db:drop', 'db:drop:geo')
    end

    desc 'GitLab | Geo | DB | Creates the Geo tracking database from config/database_geo.yml for the current RAILS_ENV.'
    task create: [:environment] do
      Rake::Task['db:create:geo'].invoke

      log_deprecated_message('geo:db:create', 'db:create:geo')
    end

    desc 'GitLab | Geo | DB | Create the Geo tracking database, load the schema, and initialize with the seed data.'
    task setup: [:environment] do
      Rake::Task['db:setup:geo'].invoke

      log_deprecated_message('geo:db:setup', 'db:setup:geo')
    end

    desc 'GitLab | Geo | DB | Migrate the Geo tracking database (options: VERSION=x, VERBOSE=false, SCOPE=blog).'
    task migrate: [:environment] do
      Rake::Task['db:migrate:geo'].invoke

      log_deprecated_message('geo:db:migrate', 'db:migrate:geo')
    end

    desc 'GitLab | Geo | DB | Rolls the schema back to the previous version (specify steps w/ STEP=n).'
    task rollback: [:environment] do
      Rake::Task['db:rollback:geo'].invoke

      log_deprecated_message('geo:db:rollback', 'db:rollback:geo')
    end

    desc 'GitLab | Geo | DB | Retrieves the current schema version number.'
    task version: [:environment] do
      Rake::Task['db:version:geo'].invoke

      log_deprecated_message('geo:db:version', 'db:version:geo')
    end

    desc 'GitLab | Geo | DB | Drops and recreates the database from ee/db/geo/structure.sql for the current environment and loads the seeds.'
    task reset: [:environment] do
      Rake::Task['db:reset:geo'].invoke

      log_deprecated_message('geo:db:reset', 'db:reset:geo')
    end

    desc 'GitLab | Geo | DB | Load the seed data from ee/db/geo/seeds.rb'
    task seed: [:environment] do
      Rake::Task['db:seed:geo'].invoke

      log_deprecated_message('geo:db:seed', 'db:seed:geo')
    end

    namespace :schema do
      desc 'GitLab | Geo | DB | Schema | Load a structure.sql file into the database'
      task load: [:environment] do
        Rake::Task['db:schema:load:geo'].invoke

        log_deprecated_message('geo:db:schema:load', 'db:schema:load:geo')
      end

      desc 'GitLab | Geo | DB | Schema | Create a ee/db/geo/structure.sql file that is portable against any DB supported by AR'
      task dump: [:environment] do
        Rake::Task['db:schema:dump:geo'].invoke

        log_deprecated_message('geo:db:schema:dump', 'db:schema:dump:geo')
      end
    end

    namespace :migrate do
      desc 'GitLab | Geo | DB | Migrate | Runs the "up" for a given migration VERSION.'
      task up: [:environment] do
        Rake::Task['db:migrate:up:geo'].invoke

        log_deprecated_message('geo:db:migrate:up', 'db:migrate:up:geo')
      end

      desc 'GitLab | Geo | DB | Migrate | Runs the "down" for a given migration VERSION.'
      task down: [:environment] do
        Rake::Task['db:migrate:down:geo'].invoke

        log_deprecated_message('geo:db:migrate:down', 'db:migrate:down:geo')
      end

      desc 'GitLab | Geo | DB | Migrate | Rollbacks the database one migration and re migrate up (options: STEP=x, VERSION=x).'
      task redo: [:environment] do
        Rake::Task['db:migrate:redo:geo'].invoke

        log_deprecated_message('geo:db:migrate:redo', 'db:migrate:redo:geo')
      end

      desc 'GitLab | Geo | DB | Migrate | Display status of migrations'
      task status: [:environment] do
        Rake::Task['db:migrate:status:geo'].invoke

        log_deprecated_message('geo:db:migrate:status', 'db:migrate:status:geo')
      end
    end

    namespace :test do
      desc 'GitLab | Geo | DB | Test | Check for pending migrations and load the test schema'
      task prepare: [:environment] do
        Rake::Task['db:test:prepare:geo'].invoke

        log_deprecated_message('geo:db:test:prepare', 'db:test:prepare:geo')
      end

      desc "GitLab | Geo | DB | Test | Recreate the test database from the current schema"
      task load: [:environment] do
        Rake::Task['db:test:load:geo'].invoke

        log_deprecated_message('geo:db:test:load', 'db:test:load:geo')
      end

      desc "GitLab | Geo | DB | Test | Empty the test database"
      task purge: [:environment] do
        Rake::Task['db:test:purge:geo'].invoke

        log_deprecated_message('geo:db:test:purge', 'db:test:purge:geo')
      end
    end
  end

  desc 'GitLab | Geo | Run orphaned project registry cleaner'
  task run_orphaned_project_registry_cleaner: :environment do
    abort GEO_LICENSE_ERROR_TEXT unless Gitlab::Geo.license_allows?

    unless Gitlab::Geo.secondary?
      abort 'This is not a secondary node'
    end

    from_project_id = ENV['FROM_PROJECT_ID'] || Geo::ProjectRegistry.minimum(:project_id)
    to_project_id = ENV['TO_PROJECT_ID'] || Geo::ProjectRegistry.maximum(:project_id)

    if from_project_id > to_project_id
      abort 'FROM_PROJECT_ID can not be greater than TO_PROJECT_ID'
    end

    batch_size = 1000
    total_count = 0
    current_max_id = 0

    until current_max_id >= to_project_id
      current_max_id = [from_project_id + batch_size, to_project_id + 1].min

      project_ids = Project
                      .where('id >= ? AND id < ?', from_project_id, current_max_id)
                      .pluck_primary_key

      orphaned_registries = Geo::ProjectRegistry
                              .where('project_id NOT IN(?)', project_ids)
                              .where('project_id >= ? AND project_id < ?', from_project_id, current_max_id)
      count = orphaned_registries.delete_all
      total_count += count

      puts "Checked project ids from #{from_project_id} to #{current_max_id} registries. Removed #{count} orphaned registries"

      from_project_id = current_max_id
    end

    puts "Orphaned registries removed(total): #{total_count}"
  end

  desc 'GitLab | Geo | Make this node the Geo primary'
  task set_primary_node: :environment do
    abort GEO_LICENSE_ERROR_TEXT unless Gitlab::Geo.license_allows?
    abort 'GitLab Geo primary node already present' if Gitlab::Geo.primary_node.present?

    Gitlab::Geo::GeoTasks.set_primary_geo_node
  end

  desc 'GitLab | Geo | Make this secondary node the primary'
  task set_secondary_as_primary: :environment do
    abort GEO_LICENSE_ERROR_TEXT unless Gitlab::Geo.license_allows?

    Gitlab::Geo::GeoTasks.set_secondary_as_primary
  end

  desc 'GitLab | Geo | Update Geo primary node URL'
  task update_primary_node_url: :environment do
    abort GEO_LICENSE_ERROR_TEXT unless Gitlab::Geo.license_allows?

    Gitlab::Geo::GeoTasks.update_primary_geo_node_url
  end

  desc 'GitLab | Geo | Print Geo node status'
  task status: :environment do
    abort GEO_LICENSE_ERROR_TEXT unless Gitlab::Geo.license_allows?

    current_node_status = GeoNodeStatus.current_node_status
    unless current_node_status
      abort 'Gitlab Geo is not configured for this site'
    end

    geo_node = current_node_status.geo_node

    unless geo_node.secondary?
      puts 'This command is only available on a secondary node'.color(:red)
      exit
    end

    Gitlab::Geo::GeoNodeStatusCheck.new(current_node_status, geo_node).print_status
  end

  namespace :site do
    desc 'GitLab | Geo | Print Geo site role'
    task role: :environment do
      current_node = GeoNode.current_node

      if current_node&.primary?
        puts 'primary'
      elsif current_node&.secondary?
        puts 'secondary'
      else
        puts 'misconfigured'
        exit 1
      end
    end
  end
end
