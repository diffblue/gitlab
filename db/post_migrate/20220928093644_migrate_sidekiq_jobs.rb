# frozen_string_literal: true

class MigrateSidekiqJobs < Gitlab::Database::Migration[2.0]
  # Migrate jobs that don't belong to current routing rules
  # https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1930
  class SidekiqMigrateJobs
    LOG_FREQUENCY = 1_000

    attr_reader :logger

    def initialize(logger: nil)
      @logger = logger
    end

    # Migrates jobs from queues that are outside the mappings
    # mappings is a hash of WorkerClassName => target_queue_name
    def migrate_queues(mappings)
      routing_rules_queues = mappings.values.uniq
      logger&.info("List of queues based on routing rules: #{routing_rules_queues}")
      Sidekiq.redis do |conn| # rubocop:disable Cop/SidekiqRedisCall
        conn.scan_each(match: "queue:*", type: 'list') do |key|
          queue_from = key.split(':').last
          next if routing_rules_queues.include? queue_from

          logger&.info("Migrating #{queue_from} queue")

          migrated = 0
          while queue_length(queue_from) > 0
            begin
              if migrated >= 0 && migrated % LOG_FREQUENCY == 0
                logger&.info("Migrating from #{queue_from}. Total: #{queue_length(queue_from)}. Migrated: #{migrated}.")
              end

              job = conn.rpop "queue:#{queue_from}"
              job_hash = Sidekiq.load_json job
              next unless mappings.has_key?(job_hash['class'])

              destination_queue = mappings[job_hash['class']]
              conn.lpush("queue:#{destination_queue}", job)
              migrated += 1
            rescue JSON::ParserError
              logger&.error("Unmarshal JSON payload from MigrateSidekiqJobs failed. Job: #{job}")
              next
            end
          end
          logger&.info("Finished migrating #{queue_from} queue")
        end
      end
    end

    private

    def queue_length(queue_name)
      Sidekiq.redis do |conn| # rubocop:disable Cop/SidekiqRedisCall
        conn.llen("queue:#{queue_name}")
      end
    end
  end

  def up
    mappings = Gitlab::SidekiqConfig.worker_queue_mappings
    logger = ::Gitlab::BackgroundMigration::Logger.build
    SidekiqMigrateJobs.new(logger: logger).migrate_queues(mappings)
  end

  def down
    # no-op
  end
end
