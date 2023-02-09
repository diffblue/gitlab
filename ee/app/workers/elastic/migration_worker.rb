# frozen_string_literal: true

module Elastic
  class MigrationWorker
    include ApplicationWorker

    data_consistency :always

    include Gitlab::ExclusiveLeaseHelpers
    # There is no onward scheduling and this cron handles work from across the
    # application, so there's no useful context to add.
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext
    include ActionView::Helpers::NumberHelper

    feature_category :global_search
    idempotent!
    urgency :low

    def perform
      return false unless preflight_check_successful?

      in_lock(self.class.name.underscore, ttl: 1.day, retries: 10, sleep_sec: 1) do
        # migration index should be checked before pulling the current_migration because if no migrations_index exists,
        # current_migration will return nil
        unless helper.migrations_index_exists?
          logger.info 'MigrationWorker: creating migrations index'
          helper.create_migrations_index
        end

        migration = Elastic::MigrationRecord.current_migration

        unless migration
          logger.info 'MigrationWorker: no migration available'
          break false
        end

        if migration.halted?
          logger.info "MigrationWorker: migration[#{migration.name}] has been halted. All future migrations will be halted because of that. Exiting"
          unpause_indexing!(migration)

          break false
        end

        if !migration.started? && migration.space_requirements?
          free_size_bytes = helper.cluster_free_size_bytes
          space_required_bytes = migration.space_required_bytes
          logger.info "MigrationWorker: migration[#{migration.name}] checking free space in cluster. Required space #{number_to_human_size(space_required_bytes)}. Free space #{number_to_human_size(free_size_bytes)}."

          if free_size_bytes < space_required_bytes
            logger.warn "MigrationWorker: migration[#{migration.name}] You should have at least #{number_to_human_size(space_required_bytes)} of free space in the cluster to run this migration. Please increase the storage in your Elasticsearch cluster."
            logger.info "MigrationWorker: migration[#{migration.name}] updating with halted: true"
            migration.halt

            break false
          end
        end

        execute_migration(migration)

        completed = migration.completed?
        logger.info "MigrationWorker: migration[#{migration.name}] updating with completed: #{completed}"
        migration.save!(completed: completed)

        unpause_indexing!(migration) if completed

        Elastic::DataMigrationService.drop_migration_has_finished_cache!(migration)
      end
    rescue StandardError => e
      logger.error("#{self.class.name}: #{e.class} #{e.message}")
    end

    private

    def preflight_check_successful?
      return false if Feature.disabled?(:elastic_migration_worker, type: :ops)
      return false unless Gitlab::CurrentSettings.elasticsearch_indexing?
      return false unless helper.alias_exists?

      if helper.unsupported_version?
        logger.info 'MigrationWorker: You are using an unsupported version of Elasticsearch. Indexing will be paused to prevent data loss'
        Gitlab::CurrentSettings.update!(elasticsearch_pause_indexing: true)

        return false
      end

      true
    end

    def execute_migration(migration)
      if migration.started? && !migration.batched? && !migration.retry_on_failure?
        logger.info "MigrationWorker: migration[#{migration.name}] did not execute migrate method since it was already executed. Waiting for migration to complete"

        return
      end

      pause_indexing!(migration)

      logger.info "MigrationWorker: migration[#{migration.name}] executing migrate method"
      migration.migrate

      if migration.batched? && !migration.completed?
        logger.info "MigrationWorker: migration[#{migration.name}] kicking off next migration batch"
        Elastic::MigrationWorker.perform_in(migration.throttle_delay)
      end
    rescue StandardError => e
      retry_migration(migration, e) if migration.retry_on_failure?

      raise e
    end

    def retry_migration(migration, exception)
      if migration.current_attempt >= migration.max_attempts
        message = "MigrationWorker: migration has failed with #{exception.class}:#{exception.message}, no retries left"
        logger.error message

        migration.fail(message: message)
      else
        logger.info "MigrationWorker: increasing previous_attempts to #{migration.current_attempt}"
        migration.save_state!(previous_attempts: migration.current_attempt)
      end
    end

    def pause_indexing!(migration)
      return unless migration.pause_indexing?
      return if migration.load_state[:pause_indexing].present?

      pause_indexing = !Gitlab::CurrentSettings.elasticsearch_pause_indexing?
      migration.save_state!(pause_indexing: pause_indexing)

      if pause_indexing
        logger.info 'MigrationWorker: Pausing indexing'
        Gitlab::CurrentSettings.update!(elasticsearch_pause_indexing: true)
      end
    end

    def unpause_indexing!(migration)
      return unless migration.pause_indexing?
      return unless migration.load_state[:pause_indexing]
      return if migration.load_state[:halted_indexing_unpaused]

      logger.info 'MigrationWorker: unpausing indexing'
      Gitlab::CurrentSettings.update!(elasticsearch_pause_indexing: false)

      migration.save_state!(halted_indexing_unpaused: true) if migration.halted?
    end

    def helper
      Gitlab::Elastic::Helper.default
    end

    def logger
      @logger ||= ::Gitlab::Elasticsearch::Logger.build
    end
  end
end
