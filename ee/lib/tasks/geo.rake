# frozen_string_literal: true

task spec: ['geo:db:test:prepare']

namespace :geo do
  GEO_LICENSE_ERROR_TEXT = 'GitLab Geo is not supported with this license. Please contact the sales team: https://about.gitlab.com/sales.'

  namespace :db do |ns|
    desc 'GitLab | Geo | DB | Drops the Geo tracking database from config/database_geo.yml for the current RAILS_ENV.'
    task drop: [:environment] do
      Gitlab::Geo::DatabaseTasks.drop_current
    end

    desc 'GitLab | Geo | DB | Creates the Geo tracking database from config/database_geo.yml for the current RAILS_ENV.'
    task create: [:environment] do
      Gitlab::Geo::DatabaseTasks.create_current
    end

    desc 'GitLab | Geo | DB | Create the Geo tracking database, load the schema, and initialize with the seed data.'
    task setup: ['geo:db:schema:load', 'geo:db:seed']

    desc 'GitLab | Geo | DB | Migrate the Geo tracking database (options: VERSION=x, VERBOSE=false, SCOPE=blog).'
    task migrate: [:environment] do
      Gitlab::Geo::DatabaseTasks.migrate

      ns['_dump'].invoke
    end

    desc 'GitLab | Geo | DB | Rolls the schema back to the previous version (specify steps w/ STEP=n).'
    task rollback: [:environment] do
      Gitlab::Geo::DatabaseTasks.rollback

      ns['_dump'].invoke
    end

    desc 'GitLab | Geo | DB | Retrieves the current schema version number.'
    task version: [:environment] do
      puts "Current version: #{Gitlab::Geo::DatabaseTasks.version}"
    end

    desc 'GitLab | Geo | DB | Drops and recreates the database from ee/db/geo/structure.sql for the current environment and loads the seeds.'
    task reset: [:environment] do
      ns['drop'].invoke
      ns['create'].invoke
      ns['setup'].invoke
    end

    desc 'GitLab | Geo | DB | Load the seed data from ee/db/geo/seeds.rb'
    task seed: [:environment] do
      ns['abort_if_pending_migrations'].invoke

      Gitlab::Geo::DatabaseTasks.load_seed
    end

    # IMPORTANT: This task won't dump the schema if ActiveRecord::Base.dump_schema_after_migration is set to false
    task _dump: [:environment] do
      if Gitlab::Geo::DatabaseTasks.dump_schema_after_migration?
        ns["schema:dump"].invoke
      end

      # Allow this task to be called as many times as required. An example is the
      # migrate:redo task, which calls other two internally that depend on this one.
      ns['_dump'].reenable
    end

    # desc "Raises an error if there are pending migrations"
    task abort_if_pending_migrations: [:environment] do
      pending_migrations = Gitlab::Geo::DatabaseTasks.pending_migrations

      if pending_migrations.any?
        puts "You have #{pending_migrations.size} pending #{pending_migrations.size > 1 ? 'migrations:' : 'migration:'}"
        pending_migrations.each do |pending_migration|
          puts '  %4d %s' % [pending_migration.version, pending_migration.name]
        end
        abort %{Run `rake geo:db:migrate` to update your database then try again.}
      end
    end

    namespace :schema do
      desc 'GitLab | Geo | DB | Schema | Load a structure.sql file into the database'
      task load: [:environment] do
        Gitlab::Geo::DatabaseTasks.load_schema_current(ActiveRecord::Base.schema_format, ENV['SCHEMA'])
      end

      desc 'GitLab | Geo | DB | Schema | Create a ee/db/geo/structure.sql file that is portable against any DB supported by AR'
      task dump: [:environment] do
        Gitlab::Geo::DatabaseTasks::Schema.dump

        ns['schema:dump'].reenable
      end
    end

    # Inform Rake that custom tasks should be run every time rake db:schema:dump is run
    Rake::Task['geo:db:schema:dump'].enhance do
      Gitlab::Geo::DatabaseTasks.with_geo_db do
        Rake::Task['gitlab:db:clean_structure_sql'].invoke
      end
    end

    namespace :migrate do
      desc 'GitLab | Geo | DB | Migrate | Runs the "up" for a given migration VERSION.'
      task up: [:environment] do
        Gitlab::Geo::DatabaseTasks::Migrate.up

        ns['_dump'].invoke
      end

      desc 'GitLab | Geo | DB | Migrate | Runs the "down" for a given migration VERSION.'
      task down: [:environment] do
        Gitlab::Geo::DatabaseTasks::Migrate.down

        ns['_dump'].invoke
      end

      desc 'GitLab | Geo | DB | Migrate | Rollbacks the database one migration and re migrate up (options: STEP=x, VERSION=x).'
      task redo: [:environment] do
        if ENV['VERSION']
          ns['migrate:down'].invoke
          ns['migrate:up'].invoke
        else
          ns['rollback'].invoke
          ns['migrate'].invoke
        end
      end

      desc 'GitLab | Geo | DB | Migrate | Display status of migrations'
      task status: [:environment] do
        Gitlab::Geo::DatabaseTasks::Migrate.status
      end
    end

    namespace :test do
      desc 'GitLab | Geo | DB | Test | Check for pending migrations and load the test schema'
      task prepare: [:environment] do
        ns['test:load'].invoke
      end

      # desc "Recreate the test database from the current schema"
      task load: [:environment, 'geo:db:test:purge'] do
        Gitlab::Geo::DatabaseTasks::Test.load
      end

      # desc "Empty the test database"
      task purge: [:environment] do
        Gitlab::Geo::DatabaseTasks::Test.purge
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
