# frozen_string_literal: true

module Gitlab
  module Database
    module PreventCrossDatabaseModification
      CrossDatabaseModificationAcrossUnsupportedTablesError = Class.new(StandardError)

      # This method will allow cross database modifications within the block
      # Example:
      #
      # allow_cross_database_modification_within_transaction(url: 'url-to-an-issue') do
      #   create(:build) # inserts ci_build and project record in one transaction
      # end
      def self.allow_cross_database_modification_within_transaction(url:)
        cross_database_context = Database::PreventCrossDatabaseModification.cross_database_context
        return yield unless cross_database_context && cross_database_context[:enabled]

        transaction_tracker_enabled_was = cross_database_context[:enabled]
        cross_database_context[:enabled] = false

        yield
      ensure
        cross_database_context[:enabled] = transaction_tracker_enabled_was if cross_database_context
      end

      def self.with_cross_database_modification_prevented(log_only: false)
        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |name, start, finish, id, payload|
          prevent_cross_database_modification!(payload[:connection], payload[:sql], log_only: log_only)
        end

        reset_cross_database_context!
        cross_database_context.merge!(enabled: true, subscriber: subscriber)

        yield if block_given?
      ensure
        cleanup_with_cross_database_modification_prevented if block_given?
      end

      def self.cleanup_with_cross_database_modification_prevented
        if cross_database_context
          ActiveSupport::Notifications.unsubscribe(PreventCrossDatabaseModification.cross_database_context[:subscriber])
          cross_database_context[:enabled] = false
        end
      end

      def self.cross_database_context
        Thread.current[:transaction_tracker]
      end

      def self.reset_cross_database_context!
        Thread.current[:transaction_tracker] = initial_data
      end

      def self.initial_data
        {
          enabled: false,
          transaction_depth_by_db: Hash.new { |h, k| h[k] = 0 },
          modified_tables_by_db: Hash.new { |h, k| h[k] = Set.new }
        }
      end

      # rubocop:disable Metrics/AbcSize
      def self.prevent_cross_database_modification!(connection, sql, log_only: false)
        return unless cross_database_context
        return unless cross_database_context[:enabled]

        return if connection.pool.instance_of?(ActiveRecord::ConnectionAdapters::NullPool)
        return if in_factory_bot_create?

        database = connection.pool.db_config.name

        # We ignore BEGIN in tests as this is the outer transaction for
        # DatabaseCleaner
        if sql.start_with?('SAVEPOINT') || (!Rails.env.test? && sql.start_with?('BEGIN'))
          cross_database_context[:transaction_depth_by_db][database] += 1

          return
        elsif sql.start_with?('RELEASE SAVEPOINT', 'ROLLBACK TO SAVEPOINT') || (!Rails.env.test? && sql.start_with?('ROLLBACK', 'COMMIT'))
          cross_database_context[:transaction_depth_by_db][database] -= 1
          if cross_database_context[:transaction_depth_by_db][database] <= 0
            cross_database_context[:modified_tables_by_db][database].clear
          end

          return
        end

        return if cross_database_context[:transaction_depth_by_db].values.all?(&:zero?)

        # PgQuery might fail in some cases due to limited nesting:
        # https://github.com/pganalyze/pg_query/issues/209
        parsed_query = PgQuery.parse(sql)
        tables = sql.downcase.include?(' for update') ? parsed_query.tables : parsed_query.dml_tables

        # We have some code where plans and gitlab_subscriptions are lazily
        # created and this causes lots of spec failures
        # https://gitlab.com/gitlab-org/gitlab/-/issues/343394
        tables -= %w[plans gitlab_subscriptions]

        return if tables.empty?

        # All migrations will write to schema_migrations in the same transaction.
        # It's safe to ignore this since schema_migrations exists in all
        # databases
        return if tables == ['schema_migrations']

        cross_database_context[:modified_tables_by_db][database].merge(tables)
        all_tables = cross_database_context[:modified_tables_by_db].values.map(&:to_a).flatten
        schemas = ::Gitlab::Database::GitlabSchema.table_schemas(all_tables)

        if schemas.many?
          message = "Cross-database data modification of '#{schemas.to_a.join(", ")}' were detected within " \
            "a transaction modifying the '#{all_tables.to_a.join(", ")}' tables." \
            "Please refer to https://docs.gitlab.com/ee/development/database/multiple_databases.html#removing-cross-database-transactions for details on how to resolve this exception."

          if schemas.any? { |s| s.to_s.start_with?("undefined") }
            message += " The gitlab_schema was undefined for one or more of the tables in this transaction. Any new tables must be added to lib/gitlab/database/gitlab_schemas.yml ."
          end

          begin
            raise Database::PreventCrossDatabaseModification::CrossDatabaseModificationAcrossUnsupportedTablesError, message
          rescue Database::PreventCrossDatabaseModification::CrossDatabaseModificationAcrossUnsupportedTablesError => e
            ::Gitlab::ErrorTracking.track_exception(e, { gitlab_schemas: schemas, tables: all_tables, query: PgQuery.normalize(sql) })
            raise unless log_only
          end
        end
      rescue StandardError => e
        # Extra safety net to ensure we never raise in production
        # if something goes wrong in this logic
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
      end
      # rubocop:enable Metrics/AbcSize

      # We ignore execution in the #create method from FactoryBot
      # because it is not representative of real code we run in
      # production. There are far too many false positives caused
      # by instantiating objects in different `gitlab_schema` in a
      # FactoryBot `create`.
      def self.in_factory_bot_create?
        caller_locations.any? { |l| l.path.end_with?('lib/factory_bot/evaluation.rb') && l.label == 'create' }
      end
    end
  end
end
