# frozen_string_literal: true

module Gitlab
  module Memory
    class Watchdog
      class Configuration
        class MonitorStack
          def initialize
            @monitors = []
          end

          def use(monitor_class, *args, **kwargs, &block)
            remove(monitor_class)
            @monitors.push(build_monitor_state(monitor_class, *args, **kwargs, &block))
          end

          def call_each
            @monitors.each do |monitor|
              yield monitor.call
            end
          end

          private

          def remove(monitor_class)
            @monitors.delete_if { |monitor| monitor.monitor_class == monitor_class }
          end

          def build_monitor_state(monitor_class, *args, max_strikes: MAX_STRIKES, **kwargs, &block)
            monitor = build_monitor(monitor_class, *args, **kwargs, &block)

            Gitlab::Memory::Watchdog::MonitorState.new(monitor, max_strikes: max_strikes)
          end

          def build_monitor(monitor_class, *args, **kwargs, &block)
            monitor_class.new(*args, **kwargs, &block)
          end
        end

        MAX_STRIKES = ENV.fetch('GITLAB_MEMWD_MAX_STRIKES', 5).to_i
        SLEEP_TIME_SECONDS = ENV.fetch('GITLAB_MEMWD_SLEEP_TIME_SEC', 60).to_i
        MAX_MEM_GROWTH = ENV.fetch('GITLAB_MEMWD_MAX_MEM_GROWTH', 3.0).to_f
        MAX_HEAP_FRAG = ENV.fetch('GITLAB_MEMWD_MAX_HEAP_FRAG', 0.5).to_f

        attr_reader :monitors
        attr_writer :logger, :handler, :sleep_time_seconds

        def initialize
          @monitors = MonitorStack.new
        end

        def handler
          @handler ||= NullHandler.instance
        end

        def logger
          @logger ||= Gitlab::Logger.new($stdout)
        end

        # Used to control the frequency with which the watchdog will wake up and poll the GC.
        def sleep_time_seconds
          @sleep_time_seconds ||= SLEEP_TIME_SECONDS
        end
      end
    end
  end
end
