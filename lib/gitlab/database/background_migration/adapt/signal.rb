# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      module Adapt
        # Base class for a signal
        class Signal
          attr_reader :indicator_class, :reason

          def initialize(indicator_class, reason:)
            @indicator_class = indicator_class
            @reason = reason
          end

          def to_s
            "Indicator '#{indicator_class}' signalled #{self.class} with reason '#{reason}'"
          end
        end

        # A StopSignal is an indication to put a migration on hold or stop it entirely:
        # In general, we want to slow down or pause the migration.
        class StopSignal < Signal; end

        # A NormalSignal indicates normal system state: We carry on with the migration
        # and may even attempt to optimize its throughput etc.
        class NormalSignal < Signal; end

        # When given an UnknownSignal, something unexpected happened while
        # we evaluated system indicators.
        class UnknownSignal < Signal; end

        # No signal could be determined, e.g. because the indicator
        # was disabled.
        class NoSignal < Signal; end
      end
    end
  end
end
