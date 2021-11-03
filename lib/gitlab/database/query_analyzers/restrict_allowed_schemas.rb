# frozen_string_literal: true

module Gitlab
  module Database
    module QueryAnalyzers
      class RestrictAllowedSchemas < Base
        UnsupportedSchemaError = Class.new(QueryAnalyzerError)
        DDLNotAllowedError = Class.new(UnsupportedSchemaError)
        DMLNotAllowedError = Class.new(UnsupportedSchemaError)
        DMLAccessDeniedError = Class.new(UnsupportedSchemaError)

        IGNORED_SCHEMAS = %i[gitlab_shared].freeze

        def self.enabled?
          true
        end

        def self.allowed_gitlab_schemas
          self.context[:allowed_gitlab_schemas]
        end

        def self.allowed_gitlab_schemas=(value)
          self.context[:allowed_gitlab_schemas] = value
        end

        def self.analyze(parsed)
          # If list of schemas is empty, we allow only DDL changes
          if self.allowed_gitlab_schemas
            self.restrict_to_dml_only(parsed)
          else
            self.restrict_to_ddl_only(parsed)
          end
        end

        def self.restrict_to_ddl_only(parsed)
          tables = self.dml_tables(parsed)
          schemas = self.dml_schemas(tables)

          if schemas.any?
            raise DMLNotAllowedError, "Select/DML queries (SELECT/UPDATE/DELETE) are disallowed in the DDL (structure) mode. " \
              "Modifying of '#{tables}' (#{schemas.to_a}) with '#{parsed.sql}'"
          end
        end

        def self.restrict_to_dml_only(parsed)
          if parsed.pg.ddl_tables.any?
            raise DDLNotAllowedError, "DDL queries (structure) are disallowed in the Select/DML (SELECT/UPDATE/DELETE) mode. " \
              "Modifying of '#{parsed.pg.ddl_tables}' with '#{parsed.sql}'"
          end

          tables = self.dml_tables(parsed)
          schemas = self.dml_schemas(tables)

          if (schemas - self.allowed_gitlab_schemas).any?
            raise DMLAccessDeniedError, "Select/DML queries (SELECT/UPDATE/DELETE) do access '#{tables}' (#{schemas.to_a}) " \
              "which is outside of list of allowed schemas: '#{self.allowed_gitlab_schemas}'."
          end
        end

        def self.dml_tables(parsed)
          parsed.pg.select_tables + parsed.pg.dml_tables
        end

        def self.dml_schemas(tables)
          extra_schemas = ::Gitlab::Database::GitlabSchema.table_schemas(tables)
          extra_schemas.subtract(IGNORED_SCHEMAS)
          extra_schemas
        end
      end
    end
  end
end
