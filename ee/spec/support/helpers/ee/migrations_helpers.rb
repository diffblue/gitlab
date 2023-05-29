# frozen_string_literal: true

module EE
  module MigrationsHelpers
    extend ::Gitlab::Utils::Override

    override :reset_column_information
    def reset_column_information(klass)
      super
    rescue ::Geo::TrackingBase::SecondaryNotConfigured
    end

    override :active_record_base
    def active_record_base(...)
      if geo_migration?
        ::Geo::TrackingBase
      else
        super
      end
    end

    override :migrations_paths
    def migrations_paths
      if geo_migration?
        geo_db_config.configuration_hash[:migrations_paths]
      else
        super
      end
    end

    override :schema_migrate_down!
    def schema_migrate_down!
      with_db_config { super }
    end

    override :schema_migrate_up!
    def schema_migrate_up!
      with_db_config { super }
    end

    override :migrate!
    def migrate!
      with_db_config { super }
    end

    def with_db_config(&block)
      if geo_migration?
        with_added_geo_connection { yield }
      else
        yield
      end
    end

    def with_added_geo_connection
      with_reestablished_active_record_base(reconnect: true) do
        reconfigure_db_connection(
          name: :geo,
          config_model: Geo::TrackingBase,
          model: ActiveRecord::Base
        )

        yield
      end
    end

    def geo_migration?
      self.class.metadata[:geo]
    end

    def geo_db_config
      Geo::TrackingBase.connection_db_config
    end
  end
end
