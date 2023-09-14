# frozen_string_literal: true

module EE
  module Gitlab
    module Database
      extend ActiveSupport::Concern

      class_methods do
        extend ::Gitlab::Utils::Override

        override :all_database_connection_files
        def all_database_connection_files
          super + Dir.glob(Rails.root.join("ee/db/database_connections/*.yaml"))
        end

        override :all_gitlab_schema_files
        def all_gitlab_schema_files
          super + Dir.glob(Rails.root.join("ee/db/gitlab_schemas/*.yaml"))
        end

        def geo_db_config_with_default_pool_size
          db_config_object = Geo::TrackingBase.connection_db_config

          config = db_config_object
            .configuration_hash
            .merge(pool: ::Gitlab::Database.default_pool_size)

          ActiveRecord::DatabaseConfigurations::HashConfig.new(
            db_config_object.env_name,
            db_config_object.name,
            config
          )
        end

        override :read_only?
        def read_only?
          ::Gitlab::Geo.secondary? || ::Gitlab.maintenance_mode?
        end
      end
    end
  end
end
