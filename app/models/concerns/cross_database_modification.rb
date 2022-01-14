# frozen_string_literal: true

module CrossDatabaseModification
  extend ActiveSupport::Concern

  included do
    private_class_method :gitlab_schema
  end

  class_methods do
    def gitlab_transactions_stack
      Thread.current[:gitlab_transactions_stack] ||= []
    end

    def transaction(**options, &block)
      if track_gitlab_schema_in_current_transaction?
        gitlab_transactions_stack.push(gitlab_schema)

        begin
          super(**options, &block)
        ensure
          gitlab_transactions_stack.pop
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
