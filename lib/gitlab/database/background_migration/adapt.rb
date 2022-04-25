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
          signal = begin
            indicator_class.new(migration.adapt_context).evaluate
          rescue StandardError => e
            Gitlab::ErrorTracking.track_exception(e, migration_id: migration.id)

            UnknownSignal.new(indicator_class, reason: "unknown error: #{e}")
          end

          case signal
          when StopSignal
            Gitlab::AppLogger.info(
              message: "Batched migration #{migration} got stop signal: #{signal}",
              migration_id: migration.id
            )

            migration.hold!
          when NormalSignal
            migration.optimize!
          when UnknownSignal
            Gitlab::AppLogger.error(
              message: "Failed to evaluate adapt signals for batched migration #{migration}: #{signal}",
              migration_id: migration.id
            )
          else
            # oblivious to what's going on, we just do nothing and carry on
          end
        end
      end
    end
  end
end
