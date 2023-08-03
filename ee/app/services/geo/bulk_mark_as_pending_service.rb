# frozen_string_literal: true

module Geo
  # Service that marks registries as pending in batches
  # to be resynchronized by Geo periodic workers later
  class BulkMarkAsPendingService
    BULK_MARK_PENDING_BATCH_SIZE = 1000
    BULK_MARK_PENDING_REDIS_KEY_PREFIX = 'geo:latest_id_marked_as_pending'

    attr_reader :registry_class

    def initialize(registry_class)
      @registry_class = registry_class.safe_constantize
    end

    # @param max_batch_count [Integer] Maximum job concurrency of Geo::BulkMarkPendingBatchWorker
    #   Avoids unnecessary counting work in Postgres
    # @return [Integer] Number of remaining batches that need to be marked as pending, up to a specified limit
    def remaining_batches_to_bulk_mark_pending(max_batch_count:)
      not_pending_count(limit: max_batch_count * BULK_MARK_PENDING_BATCH_SIZE)
        .fdiv(BULK_MARK_PENDING_BATCH_SIZE)
        .ceil
    end

    # Marks one batch of rows as pending to sync, and updates the cursor for the next batch.
    # This is called by Geo::BulkMarkPendingBatchWorker
    # @return [Integer] The number of rows affected
    def bulk_mark_pending_one_batch!
      # If you want to add concurrency, look into using a custom SQL update query with a RETURNING clause.
      # At the moment, the worker is run one-at-a-time, and other race conditions should have minimal impact.
      last_id = one_batch_to_bulk_mark_pending_relation.maximum(registry_class.primary_key)

      rows_updated = one_batch_to_bulk_mark_pending_relation
                       .update_all(state: registry_class::STATE_VALUES[:pending], last_synced_at: nil)

      # We save the latest registry ID processed in Redis so we can keep track of it
      # to avoid updating the same batch of rows again if other jobs
      # like Geo::RepositorySyncWorker or Geo::RegistrySyncWorker change
      # the state of those rows (to not pending) while the batch update was executing
      set_bulk_mark_pending_cursor(last_id)

      rows_updated
    end

    def set_bulk_mark_pending_cursor(last_id_updated)
      Gitlab::Redis::SharedState.with do |redis|
        redis.set("#{BULK_MARK_PENDING_REDIS_KEY_PREFIX}:#{registry_class.table_name}", last_id_updated)
      end
    end

    private

    # The number of remaining rows that need resynchronization, up to a specified limit
    # @param limit [Integer] Limits the number of rows counted
    # @return [Integer] Number of rows that need resynchronization, up to a limit
    def not_pending_count(limit:)
      registry_class.not_pending.limit(limit).count
    end

    # @return [ActiveRecord::Relation] A single batch of rows that needs resynchronization
    def one_batch_to_bulk_mark_pending_relation
      registry_class.not_pending.ordered
                    .limit(BULK_MARK_PENDING_BATCH_SIZE)
                    .where("id > ?", get_bulk_mark_pending_cursor) # rubocop: disable CodeReuse/ActiveRecord
    end

    def get_bulk_mark_pending_cursor
      Gitlab::Redis::SharedState.with do |redis|
        redis.get("#{BULK_MARK_PENDING_REDIS_KEY_PREFIX}:#{registry_class.table_name}").to_i
      end
    end
  end
end
