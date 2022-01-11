# frozen_string_literal: true

module CrossDatabaseModification
  extend ActiveSupport::Concern

  included do
    private_class_method :gitlab_schema
  end

  class_methods do
    def transaction(**options, &block)
      if track_gitlab_schema_in_current_transaction?
        super(**options) do
          if connection.current_transaction.respond_to?(:add_gitlab_schema) && gitlab_schema
            connection.current_transaction.add_gitlab_schema(gitlab_schema)
          end

          yield
        end
      else
        super(**options, &block)
      end
    end

    def track_gitlab_schema_in_current_transaction?
      return false unless Feature::FlipperFeature.table_exists?

      Feature.enabled?(:track_gitlab_schema_in_current_transaction, default_enabled: :yaml)
    rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad
      false
    end

    def gitlab_schema
      case self.name
      when 'ActiveRecord::Base', 'ApplicationRecord'
        :gitlab_main
      when 'Ci::ApplicationRecord'
        :gitlab_ci
      else
        Gitlab::Database::GitlabSchema.table_schema(table_name) if table_name
      end
    end
  end
end
