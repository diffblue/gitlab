# frozen_string_literal: true

module Gitlab
  module Memory
    class Watchdog
      class Configuration
        class MonitorStack
          def initialize
            @monitors = []
          end

          def use(klass, *args, &block)
            @monitors.push(build_monitor(klass, args, block))
          end

          def each
            @monitors.each do |monitor|
              yield monitor
            end
          end

          def build_monitor(klass, args, block)
            klass.new(*args, &block)
          end
        end

        DEFAULT_SLEEP_TIME_SECONDS = 60

        attr_reader :monitors
        attr_writer :logger, :handler, :sleep_time_seconds

        def initialize
          @monitors = MonitorStack.new
        end

        def handler
          @handler ||= NullHandler.instance
        end

        def logger
          @logger ||= Logger.new($stdout)
        end

        # Used to control the frequency with which the watchdog will wake up and poll the GC.
        def sleep_time_seconds
          @sleep_time_seconds ||= ENV['GITLAB_MEMWD_SLEEP_TIME_SEC']&.to_i || DEFAULT_SLEEP_TIME_SECONDS
        end
      end
    end
  end
end
