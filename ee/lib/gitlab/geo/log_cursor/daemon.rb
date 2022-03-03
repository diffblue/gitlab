# frozen_string_literal: true

module Gitlab
  module Geo
    module LogCursor
      class Daemon
        VERSION = '0.2.0'
        BATCH_SIZE = 250
        SECONDARY_CHECK_INTERVAL = 60
        MAX_ERROR_DURATION = 1800

        attr_reader :options

        def initialize(options = {})
          @options = options
          @exit = false
          @failing_since = nil
        end

        def run!
          logger.debug('#run!: start')
          trap_signals

          run_once! until exit?

          logger.debug('#run!: finish')
        end

        def run_once!
          # Prevent the node from processing events unless it's a secondary
          unless Geo.secondary?
            logger.debug("#run!: not a secondary, sleeping for #{SECONDARY_CHECK_INTERVAL} secs")
            sleep_break(SECONDARY_CHECK_INTERVAL)
            return
          end

          lease = Lease.try_obtain_with_ttl { find_and_handle_events! }

          handle_error(lease[:error])

          # When no new event is found sleep for a few moments
          sleep_break(lease[:ttl])
        end

        def find_and_handle_events!
          gap_tracking.fill_gaps { |event_log| handle_single_event(event_log) }

          # Wrap this with the connection to make it possible to reconnect if
          # PGbouncer dies: https://github.com/rails/rails/issues/29189
          ::Geo::EventLog.connection_pool.with_connection do
            LogCursor::EventLogs.new.fetch_in_batches do |batch, last_id|
              break if exit?

              handle_events(batch, last_id)
            end
          end
        end

        private

        def handle_error(error)
          track_failing_since(error)

          if excessive_errors?
            exit!("Consecutive errors for over #{MAX_ERROR_DURATION} seconds")
          end
        end

        def track_failing_since(error)
          if error
            @failing_since ||= Time.now.utc
          else
            @failing_since = nil
          end
        end

        def excessive_errors?
          return unless @failing_since

          (Time.now.utc - @failing_since) > MAX_ERROR_DURATION
        end

        def handle_events(batch, previous_batch_last_id)
          logger.info("#handle_events:", first_id: batch.first.id, last_id: batch.last.id)

          gap_tracking.previous_id = previous_batch_last_id

          batch.each do |event_log|
            gap_tracking.check!(event_log.id)

            handle_single_event(event_log)
          end
        end

        def handle_single_event(event_log)
          event = event_log.event

          # If a project is deleted, the event log and its associated event data
          # could be purged from the log. We ignore this and move along.
          unless event
            logger.warn("#handle_single_event: unknown event", event_log_id: event_log.id)
            return
          end

          unless can_replay?(event_log)
            logger.event_info(event_log.created_at, 'Skipped event', event_data(event_log))
            return
          end

          process_event(event, event_log)
        end

        def process_event(event, event_log)
          event_klass_for(event).new(event, event_log.created_at, logger).process
        rescue NoMethodError => e
          logger.error(e.message)
          raise e
        end

        def event_klass_for(event)
          event_klass_name = event.consumer_klass_name
          current_namespace = self.class.name.deconstantize
          Object.const_get("#{current_namespace}::Events::#{event_klass_name}", false)
        end

        def trap_signals
          trap(:TERM) { quit!(:term) }
          trap(:INT) { quit!(:int) }
        end

        # Safe shutdown
        def quit!(signal)
          warn("Signal #{signal} received, Exiting...")

          @exit = true
        end

        def exit!(error_message)
          logger.error("Exiting due to: #{error_message}") if error_message

          @exit = true
        end

        def exit?
          @exit
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def can_replay?(event_log)
          return true if event_log.project_id.nil?

          # Always replay events for deleted projects
          return true unless Project.exists?(event_log.project_id)

          Gitlab::Geo.current_node&.projects_include?(event_log.project_id)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        # Sleeps for the specified duration plus some random seconds.
        #
        # This allows multiple GeoLogCursors to randomly process a batch of events,
        # without favouring the shortest path (or latency).
        #
        # Exits early if needed.
        def sleep_break(seconds)
          sleep(random_jitter_time)

          seconds.to_i.times do
            break if exit?

            sleep(1)
          end
        end

        # Returns a random float from 0.1 to 2.0
        def random_jitter_time
          rand(1..20) * 0.1
        end

        def gap_tracking
          @gap_tracking ||= ::Gitlab::Geo::EventGapTracking.new(logger)
        end

        def logger
          @logger ||= Gitlab::Geo::LogCursor::Logger.new(self.class, log_level)
        end

        def log_level
          debug_logging? ? :debug : Rails.logger.level
        end

        def debug_logging?
          options[:debug]
        end

        def event_data(event_log)
          {
            event_log_id: event_log.id,
            event_id: event_log.event.id,
            event_type: event_log.event.class.name,
            project_id: event_log.project_id
          }
        end
      end
    end
  end
end
