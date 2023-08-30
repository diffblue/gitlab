# frozen_string_literal: true

module Geo
  class BaseBulkUpdateService
    BULK_MARK_UPDATE_BATCH_SIZE = 1_000
    BULK_MARK_UPDATE_ROW_SCAN_MAX = 10_000

    attr_reader :registry_class

    def initialize(registry_class)
      @registry_class = registry_class.safe_constantize
    end

    # @param max_batch_count [Integer] Maximum job concurrency of bulk mark update batch workers
    #                                  Avoids unnecessary counting work in Postgres
    # @return [Integer] Number of remaining batches that need to be updated, up to a specified limit
    def remaining_batches_to_bulk_mark_update(max_batch_count:)
      pending_to_update_count(limit: max_batch_count * BULK_MARK_UPDATE_BATCH_SIZE)
        .fdiv(BULK_MARK_UPDATE_BATCH_SIZE)
        .ceil
    end

    # Marks one batch of rows with the new state and updates the cursor for the next batch.
    # This is called by workers like BulkMarkPendingBatchWorker and BulkMarkVerificationPendingBatchWorker.
    # @return [Integer] The number of rows affected
    def bulk_mark_update_one_batch!
      # If you want to add concurrency, look into using a custom SQL update query with a RETURNING clause.
      # At the moment, the worker is run one-at-a-time, and other race conditions should have minimal impact.
      last_id = one_batch_to_bulk_update_relation.maximum(registry_class.primary_key)

      rows_updated = one_batch_to_bulk_update_relation.update_all(**attributes_to_update)

      # We save the latest registry ID processed in Redis so we can keep track of it
      # to avoid updating the same batch of rows again if other jobs
      # like Geo::RepositorySyncWorker, Geo::RegistrySyncWorker or Geo::VerificationBatchWorker change
      # the state of those rows while the batch update was executing
      set_bulk_mark_update_cursor(last_id)

      rows_updated
    end

    def set_bulk_mark_update_cursor(last_id_updated)
      Gitlab::Redis::SharedState.with do |redis|
        redis.set("#{bulk_mark_update_redis_key_prefix}:#{registry_class.table_name}", last_id_updated)
      end
    end

    private

    def bulk_mark_update_name
      raise NotImplementedError
    end

    def attributes_to_update
      raise NotImplementedError
    end

    def pending_to_update_relation
      raise NotImplementedError
    end

    # Method that counts the number of registries that need to be updated up to a specified limit
    # @param [Integer] limit Limits the number of rows counted
    def pending_to_update_count(limit:)
      pending_to_update_relation.limit(limit).count
    end

    def one_batch_to_bulk_update_relation
      pending_to_update_relation
        .ordered_by_id
        .limit(BULK_MARK_UPDATE_BATCH_SIZE)
        .after_bulk_mark_update_cursor(get_bulk_mark_update_cursor)
        .before_bulk_mark_update_row_scan_max(get_bulk_mark_update_cursor, BULK_MARK_UPDATE_ROW_SCAN_MAX)
    end

    def bulk_mark_update_redis_key_prefix
      "geo:latest_id_marked_as_#{bulk_mark_update_name}"
    end

    def get_bulk_mark_update_cursor
      Gitlab::Redis::SharedState.with do |redis|
        redis.get("#{bulk_mark_update_redis_key_prefix}:#{registry_class.table_name}").to_i
      end
    end
  end
end
