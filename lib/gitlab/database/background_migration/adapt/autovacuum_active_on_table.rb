# frozen_string_literal: true

require_relative 'signal'

module Gitlab
  module Database
    module BackgroundMigration
      module Adapt
        class AutovacuumActiveOnTable
          attr_reader :context

          def initialize(context)
            @context = context
          end

          def evaluate
            autovacuum_active_on = active_autovacuums_for(context.tables)

            return normal_signal if autovacuum_active_on.empty? || !enabled?

            StopSignal.new(self.class, reason: "autovacuum running on: #{autovacuum_active_on.join(', ')}")
          end

          private

          def enabled?
            Feature.enabled?(:batched_migrations_adapt_on_autovacuum, type: :ops, default_enabled: :yaml)
          end

          def normal_signal
            NormalSignal.new(self.class, reason: "no autovacuum running on any relevant tables")
          end

          def active_autovacuums_for(tables)
            Gitlab::Database::PostgresAutovacuumActivity.for_tables(tables)
          end
        end
      end
    end
  end
end
