# frozen_string_literal: true

module Gitlab
  module Memory
    class Watchdog
      module Monitors
        class BaseMonitor
          DEFAULT_MAX_STRIKES = 5

          attr_reader :strikes, :max_strikes

          # max_strikes:
          #   How many times the process is allowed to be above certain threshold before
          #   a memory_violation_callback is invoked. The duration for which a process may be above a certain
          #   threshold is computed as `max_strikes * sleep_time_seconds`.
          def initialize(max_strikes: ENV['GITLAB_MEMWD_MAX_STRIKES']&.to_i || DEFAULT_MAX_STRIKES)
            @max_strikes = max_strikes
            @strikes = 0

            init_prometheus_metrics
          end

          # Whenever a violation occurs a strike is issued.
          # If the maximum number of strikes are reached,
          # a memory_violation_callback is invoked to deal with the situation.

          # memory_violation_callback: a callback for handling memory violation
          def call(memory_violation_callback:)
            refresh_state

            update_strikes

            return unless above_the_limit?

            @counter_violations.increment(reason: reason)

            return unless memory_violation_callback && max_strikes_exceeded?

            @counter_violations_handled.increment(reason: reason)
            memory_violation_callback.call(payload)
            reset_strikes
          end

          private

          # Can be overridden
          def above_the_limit?
            false
          end

          # Can be overridden
          def refresh_state
            # NOP
          end

          # Can be overridden
          def payload
            {
              worker_id: worker_id,
              memwd_max_strikes: @max_strikes,
              memwd_cur_strikes: @strikes,
              memwd_rss_bytes: process_rss_bytes
            }
          end

          def max_strikes_exceeded?
            @strikes > @max_strikes
          end

          def update_strikes
            if above_the_limit?
              @strikes += 1
            else
              @strikes = 0
            end
          end

          def reset_strikes
            @strikes = 0
          end

          def reason
            self.class.name.demodulize.delete_suffix('Monitor').underscore.to_s
          end

          def process_rss_bytes
            Gitlab::Metrics::System.memory_usage_rss
          end

          def init_prometheus_metrics
            default_labels = { pid: worker_id }
            @counter_violations = Gitlab::Metrics.counter(
              :gitlab_memwd_violations_total,
              'Total number of times a Ruby process violated a memory threshold',
              default_labels
            )
            @counter_violations_handled = Gitlab::Metrics.counter(
              :gitlab_memwd_violations_handled_total,
              'Total number of times Ruby process memory violations were handled',
              default_labels
            )
          end

          def worker_id
            ::Prometheus::PidProvider.worker_id
          end
        end
      end
    end
  end
end
