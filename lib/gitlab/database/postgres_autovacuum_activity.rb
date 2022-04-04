# frozen_string_literal: true

module Gitlab
  module Database
    class PostgresAutovacuumActivity < SharedModel
      self.table_name = 'postgres_autovacuum_activity'
      self.primary_key = 'table_identifier'

      scope :for_tables, ->(tables) { where('schema = current_schema()').where(table: tables) }

      def to_s
        "table #{table_identifier} (started: #{vacuum_start})"
      end
    end
  end
end
