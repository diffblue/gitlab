# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class MultiDatabasePartitionManager
        def initialize(models)
          @models = models
        end

        def sync_partitions
          return if models.empty?

          each_database_connection do
            PartitionManager.new(models).sync_partitions
          end
        end

        private

        attr_reader :models

        def each_database_connection(&block)
          original_db_config = ActiveRecord::Base.connection_db_config # rubocop:disable Database/MultipleDatabases

          begin
            with_each_connection(&block)
          ensure
            ActiveRecord::Base.establish_connection(original_db_config) # rubocop:disable Database/MultipleDatabases
          end
        end

        def with_each_connection
          Gitlab::Database.db_config_names.each do |db_name|
            config_for_db_name = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: db_name) # rubocop:disable Database/MultipleDatabases

            ActiveRecord::Base.establish_connection(config_for_db_name)

            yield
          end
        end
      end
    end
  end
end
