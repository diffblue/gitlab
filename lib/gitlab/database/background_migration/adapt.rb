# frozen_string_literal: true

require_relative 'adapt/signal'

module Gitlab
  module Database
    module BackgroundMigration
      module Adapt
        # Rather than passing along the migration, we use a more explicitly defined context
        Context = Struct.new(:tables)

        # The adapt! method evaluates system indicators and evaluates their signals.
        # Based on this, the migration is being put on hold for a while or further
        # optimized to increase throughput.
        #
        # The implementation is robust to errors and expected not to raise unexpected
        # errors when evaluating system indicators.
        def self.adapt!(migration, indicator_class = AutovacuumActiveOnTable)
          return unless Feature.enabled?(:adapt_batched_migrations, type: :ops, default_enabled: :yaml)

          signal = begin
            indicator_class.new(migration.adapt_context).evaluate
          rescue StandardError => e
            UnknownSignal.new(indicator_class, reason: "unknown error: #{e}")
          end

          case signal
          when StopSignal
            migration.hold!
          when NormalSignal
            migration.optimize!
          when UnknownSignal
            Gitlab::AppLogger.error("Failed to evaluate adapt signals for background migration: #{signal}")
          else
            # oblivious to what's going on, we just do nothing and carry on
          end
        end
      end
    end
  end
end
