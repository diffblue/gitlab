# frozen_string_literal: true

module Elastic
  module BulkCronWorker
    extend ActiveSupport::Concern

    RESCHEDULE_INTERVAL = 1.second

    included do
      include ApplicationWorker
      include Gitlab::ExclusiveLeaseHelpers
      # There is no onward scheduling and this cron handles work from across the
      # application, so there's no useful context to add.
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext
    end

    def perform(shard_number = nil)
      if Elastic::IndexingControl.non_cached_pause_indexing?
        logger.info(message: "elasticsearch_pause_indexing setting is enabled. #{self.class} execution is skipped.")
        return false
      end

      if shard_number
        process_shard(shard_number)
      elsif Feature.enabled?(:parallel_bulk_cron_worker)
        schedule_shards
      else
        process_all_shards
      end
    rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
      # We're scheduled on a cronjob, so nothing to do here
    end

    private

    def process_shard(shard_number)
      return if legacy_lock_exists? # skip execution if legacy lease is still obtained

      in_lock("#{self.class.name.underscore}/shard/#{shard_number}", ttl: 10.minutes, retries: 10, sleep_sec: 1) do
        service.execute(shards: [shard_number]).tap do |records_count|
          log_extra_metadata_on_done(:records_count, records_count)
          log_extra_metadata_on_done(:shard_number, shard_number)

          # Requeue current worker if the queue isn't empty
          self.class.perform_in(RESCHEDULE_INTERVAL, shard_number) if should_requeue?(records_count)
        end
      end
    end

    def schedule_shards
      return if legacy_lock_exists? # skip execution if legacy lease is still obtained

      Elastic::ProcessBookkeepingService::SHARDS.each do |shard_number|
        self.class.perform_async(shard_number)
      end
    end

    def process_all_shards
      in_lock(self.class.name.underscore, ttl: 10.minutes, retries: 10, sleep_sec: 1) do
        service.execute.tap do |records_count|
          log_extra_metadata_on_done(:records_count, records_count)

          # Requeue current worker if the queue isn't empty
          self.class.perform_in(RESCHEDULE_INTERVAL) if should_requeue?(records_count)
        end
      end
    end

    def legacy_lock_exists?
      !!Gitlab::ExclusiveLease.get_uuid(self.class.name.underscore)
    end

    def should_requeue?(records_count)
      return false unless records_count

      records_count > 0 && Feature.enabled?(:bulk_cron_worker_auto_requeue)
    end

    def logger
      Elastic::IndexingControl.logger
    end
  end
end
