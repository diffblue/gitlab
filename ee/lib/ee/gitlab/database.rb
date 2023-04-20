# frozen_string_literal: true

module EE
  module Gitlab
    module Database
      extend ActiveSupport::Concern

      EMBEDDING_DATABASE_NAME = 'embedding'
      EMBEDDING_DATABASE_DIR  = 'ee/db/embedding'

      GEO_DATABASE_NAME = 'geo'
      GEO_DATABASE_DIR  = 'ee/db/geo'

      EE_DATABASES_NAME_TO_DIR = {
        EMBEDDING_DATABASE_NAME => EMBEDDING_DATABASE_DIR,
        GEO_DATABASE_NAME => GEO_DATABASE_DIR
      }.freeze

      class_methods do
        extend ::Gitlab::Utils::Override

        override :all_database_names
        def all_database_names
          super + EE_DATABASES_NAME_TO_DIR.keys
        end

        override :check_postgres_version_and_print_warning
        def check_postgres_version_and_print_warning
          super
        rescue ::Geo::TrackingBase::SecondaryNotConfigured
          # ignore - happens when Rake tasks yet have to create a database, e.g. for testing
        end

        override :database_base_models
        def database_base_models
          @database_base_models_ee ||= super.merge(
            embedding: ::Embedding::ApplicationRecord.connection_class? ? ::Embedding::ApplicationRecord : nil,
            geo: ::Geo::TrackingBase.connection_class? ? ::Geo::TrackingBase : nil
          ).compact.with_indifferent_access.freeze
        end

        override :database_base_models_using_load_balancing
        def database_base_models_using_load_balancing
          @database_base_models_using_load_balancing ||= super.merge(
            embedding: ::Embedding::ApplicationRecord.connection_class? ? ::Embedding::ApplicationRecord : nil
          ).compact.with_indifferent_access.freeze
        end

        override :schemas_to_base_models
        def schemas_to_base_models
          @schemas_to_base_models_ee ||= super.merge(
            gitlab_embedding: [self.database_base_models[:embedding]].compact,
            gitlab_geo: [self.database_base_models[:geo]].compact
          ).compact.with_indifferent_access.freeze
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
