# frozen_string_literal: true

module Geo
  # Accepts a registry class, queries the next batch of replicable records, and
  # creates any missing registries.
  class RegistryConsistencyService
    include ::Gitlab::Geo::LogHelpers

    attr_reader :registry_class, :model_class, :batch_size

    def initialize(registry_class, batch_size:)
      @registry_class = registry_class
      @model_class = registry_class::MODEL_CLASS
      @batch_size = batch_size
    end

    # @return [Boolean] whether at least one registry has been created or deleted in range
    def execute
      range = next_range!
      return unless range

      created_in_range, deleted_in_range = handle_differences_in_range(range)
      created_above, deleted_above = create_missing_above(end_of_batch: range.last)

      [created_in_range, deleted_in_range, created_above, deleted_above].flatten.compact.any?
    rescue StandardError => e
      log_error("Error while backfilling #{registry_class}", e)

      raise
    end

    private

    # @return [Range] the next range of a batch of records
    def next_range!
      Gitlab::Geo::RegistryBatcher.new(registry_class, key: batcher_key, batch_size: batch_size).next_range!
    end

    def batcher_key
      "registry_consistency:#{registry_class.name.parameterize}"
    end

    def handle_differences_in_range(range)
      untracked, unused = find_registry_differences(range)

      created_in_range = create_untracked_in_range(untracked)
      log_created(range, untracked, created_in_range)

      deleted_in_range = delete_unused_in_range(unused)
      log_deleted(range, unused, deleted_in_range)

      [created_in_range, deleted_in_range]
    end

    # @return [Array] the list of IDs of created records
    def create_untracked_in_range(untracked)
      return [] if untracked.empty?

      registry_class.insert_for_model_ids(untracked)
    end

    # @return [Array] the list of IDs of deleted records
    def delete_unused_in_range(delete_unused_in_range)
      return [] if delete_unused_in_range.empty?

      registry_class.delete_for_model_ids(delete_unused_in_range)
    end

    def find_registry_differences(range)
      registry_class.find_registry_differences(range)
    end

    # This hack is used to sync new files soon after they are created.
    #
    # This is not needed for replicables that have already implemented
    # create events.
    #
    # @param [Integer] end_of_batch the last ID of the batch processed in create_untracked_in_range
    # @return [Array] the list of IDs of created records
    def create_missing_above(end_of_batch:)
      return [] if registry_class.has_create_events?
      return [] unless model_class.any?

      last_id = model_class.last.id

      # When the LoopingBatcher will soon approach the end of the table, it
      # finds the records at the end of the table anyway, so conserve resources.
      return [] if batch_close_to_the_end?(end_of_batch, last_id)

      # Try to call this service often enough that batch_size is greater than
      # the number of recently created records since last call.
      start = last_id - batch_size + 1
      finish = last_id

      handle_differences_in_range(start..finish)
    end

    # Returns true when LoopingBatcher will soon return ranges near the end of
    # the table.
    #
    # @return [Boolean] true if the end_of_batch ID is near the end of the table
    def batch_close_to_the_end?(end_of_batch, last_id)
      last_id < end_of_batch + 5 * batch_size
    end

    def log_created(range, untracked, created)
      log_info(
        "Created registry entries",
        {
          registry_class: registry_class.name,
          start: range.first,
          finish: range.last,
          created: created.length,
          failed_to_create: untracked.length - created.length
        }
      )
    end

    def log_deleted(range, unused, deleted)
      log_info(
        "Deleted registry entries",
        {
          registry_class: registry_class.name,
          start: range.first,
          finish: range.last,
          deleted: deleted.length,
          failed_to_delete: unused.length - deleted.length
        }
      )
    end
  end
end
