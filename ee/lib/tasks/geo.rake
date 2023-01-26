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
      task name => ["db:create:#{name}", :environment, "db:schema:load:#{name}", "db:seed:#{name}"]
    end
  end

  namespace :version do
    ActiveRecord::Tasks::DatabaseTasks.for_each(databases) do |name|
      desc "Retrieves the current #{name} database schema version number"
      # rubocop:disable Database/MultipleDatabases
      task name => :load_config do
        original_db_config = ActiveRecord::Base.connection_db_config
        db_config = ActiveRecord::Base.configurations.configs_for(env_name: ActiveRecord::Tasks::DatabaseTasks.env, name: name)
        ActiveRecord::Base.establish_connection(db_config) # rubocop: disable Database/EstablishConnection
        puts "Current version: #{ActiveRecord::Base.connection.migration_context.current_version}"
      ensure
        ActiveRecord::Base.establish_connection(original_db_config) if original_db_config # rubocop: disable Database/EstablishConnection
      end
      # rubocop:enable Database/MultipleDatabases
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
      db_namespace["abort_if_pending_migrations:geo"].invoke
      ActiveRecord::Tasks::DatabaseTasks.seed_loader = seed_loader
      ActiveRecord::Tasks::DatabaseTasks.load_seed
    end
  end
end

namespace :geo do
  GEO_LICENSE_ERROR_TEXT = 'GitLab Geo is not supported with this license. Please contact the sales team: https://about.gitlab.com/sales.'

  desc 'GitLab | Geo | Run orphaned project registry cleaner'
  task run_orphaned_project_registry_cleaner: :environment do
    abort GEO_LICENSE_ERROR_TEXT unless Gitlab::Geo.license_allows?

    unless Gitlab::Geo.secondary?
      abort 'This is not a secondary node'
    end

    from_project_id = ENV.fetch('FROM_PROJECT_ID', Geo::ProjectRegistry.minimum(:project_id)).to_i
    to_project_id = ENV.fetch('TO_PROJECT_ID', Geo::ProjectRegistry.maximum(:project_id)).to_i

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
