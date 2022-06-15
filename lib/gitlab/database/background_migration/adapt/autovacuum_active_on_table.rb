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

            return NoSignal.new(self.class, reason: 'indicator disabled') unless enabled?

            if autovacuum_active_on.empty?
              NormalSignal.new(self.class, reason: 'no autovacuum running on any relevant tables')
            else
              StopSignal.new(self.class, reason: "autovacuum running on: #{autovacuum_active_on.join(', ')}")
            end
          end

          private

          def enabled?
            Feature.enabled?(:batched_migrations_adapt_on_autovacuum, type: :ops)
          end

          def active_autovacuums_for(tables)
            Gitlab::Database::PostgresAutovacuumActivity.for_tables(tables)
          end
        end
      end
    end
  end
end
