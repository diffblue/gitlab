# frozen_string_literal: true

module Gitlab
  module Memory
    class Watchdog
      module Monitors
        # A monitor that observes Ruby heap fragmentation and calls
        # memory_violation_callback when the Ruby heap has been fragmented for an extended
        # period of time.
        #
        # See Gitlab::Metrics::Memory for how heap fragmentation is defined.
        class HeapFragmentationMonitor < BaseMonitor
          extend ::Gitlab::Utils::Override

          DEFAULT_MAX_HEAP_FRAG = 0.5

          attr_reader :max_heap_fragmentation

          # max_heap_fragmentation:
          #   The degree to which the Ruby heap is allowed to be fragmented. Range [0,1].
          def initialize(
            max_heap_fragmentation: ENV['GITLAB_MEMWD_MAX_HEAP_FRAG']&.to_f || DEFAULT_MAX_HEAP_FRAG,
            **options)
            super(**options)

            @max_heap_fragmentation = max_heap_fragmentation
            init_frag_limit_metrics
          end

          private

          override :above_the_limit?
          def above_the_limit?
            @heap_fragmentation > @max_heap_fragmentation
          end

          override :refresh_state
          def refresh_state
            @heap_fragmentation = Gitlab::Metrics::Memory.gc_heap_fragmentation
          end

          override :payload
          def payload
            super.merge(message: 'heap fragmentation limit exceeded',
                        memwd_cur_heap_frag: @heap_fragmentation,
                        memwd_max_heap_frag: @max_heap_fragmentation)
          end

          def init_frag_limit_metrics
            @heap_frag_limit = Gitlab::Metrics.gauge(
              :gitlab_memwd_heap_frag_limit,
              'The configured limit for how fragmented the Ruby heap is allowed to be'
            )
            @heap_frag_limit.set({}, @max_heap_fragmentation)
          end
        end
      end
    end
  end
end
