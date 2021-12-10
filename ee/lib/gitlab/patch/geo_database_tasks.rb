# frozen_string_literal: true

module Gitlab
  module Patch
    module GeoDatabaseTasks
      def dump_filename(db_config_name, format = ApplicationRecord.schema_format)
        return super unless Gitlab::Database.geo_database?(db_config_name)

        Rails.root.join(Gitlab::Database::GEO_DATABASE_DIR, 'structure.sql').to_s
      end

      def cache_dump_filename(db_config_name, schema_cache_path: nil)
        return super unless Gitlab::Database.geo_database?(db_config_name)

        Rails.root.join(Gitlab::Database::GEO_DATABASE_DIR, 'schema_cache.yml').to_s
      end
    end
  end
end
