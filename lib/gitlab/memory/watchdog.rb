# frozen_string_literal: true

module Gitlab
  module Memory
    # A background thread that monitors Ruby memory and calls
    # into a handler when the Ruby process violates defined limits
    # for an extended period of time.
    class Watchdog
      # This handler does nothing. It returns `false` to indicate to the
      # caller that the situation has not been dealt with so it will
      # receive calls repeatedly if fragmentation remains high.
      #
      # This is useful for "dress rehearsals" in production since it allows
      # us to observe how frequently the handler is invoked before taking action.
      class NullHandler
        include Singleton

        def call
          # NOP
          false
        end
      end

      # This handler sends SIGTERM and considers the situation handled.
      class TermProcessHandler
        def initialize(pid = $$)
          @pid = pid
        end

        def call
          Process.kill(:TERM, @pid)
          true
        end
      end

      # This handler invokes Puma's graceful termination handler, which takes
      # into account a configurable grace period during which a process may
      # remain unresponsive to a SIGTERM.
      class PumaHandler
        def initialize(puma_options = ::Puma.cli_config.options)
          @worker = ::Puma::Cluster::WorkerHandle.new(0, $$, 0, puma_options)
        end

        def call
          @worker.term
          true
        end
      end

      def initialize
        @configuration = Configuration.new
        @alive = true
      end

      def configure(&block)
        yield(@configuration)
      end

      def call
        logger.info(log_labels.merge(message: 'started'))

        while @alive
          sleep(sleep_time_seconds)

          monitor if Feature.enabled?(:gitlab_memory_watchdog, type: :ops)
        end

        logger.info(log_labels.merge(message: 'stopped'))
      end

      def stop
        @alive = false
      end

      def memory_violation_callback
        lambda do |payload|
          return unless @alive

          all_labels = log_labels.merge(payload)
          logger.warn(all_labels)

          @alive = !handler.call
        end
      end

      private

      def monitor
        @configuration.monitors.each do |monitor|
          monitor.call(memory_violation_callback: memory_violation_callback)
        end
      end

      def handler
        # This allows us to keep the watchdog running but turn it into "friendly mode" where
        # all that happens is we collect logs and Prometheus events for fragmentation violations.
        return NullHandler.instance unless Feature.enabled?(:enforce_memory_watchdog, type: :ops)

        @configuration.handler
      end

      def logger
        @configuration.logger
      end

      def sleep_time_seconds
        @configuration.sleep_time_seconds
      end

      def log_labels
        {
          pid: $$,
          memwd_handler_class: handler.class.name,
          memwd_sleep_time_s: sleep_time_seconds
        }
      end
    end
  end
end
