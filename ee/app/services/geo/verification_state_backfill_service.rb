# frozen_string_literal: true

module Geo
  class VerificationStateBackfillService
    include ::Gitlab::Geo::LogHelpers

    attr_reader :replicable_model, :batch_size

    delegate :primary_key, :verification_state_table_name, :verification_state_model_key, :verification_arel_table, :verification_state_table_class, to: :replicable_model

    def initialize(replicable_model, batch_size:)
      @replicable_model = replicable_model
      @batch_size = batch_size
    end

    # Gets the next batch of rows from the replicable table, and inserts and
    # deletes corresponding rows in the verification state table.
    #
    # @return [Boolean] whether any rows needed to be inserted or deleted
    def execute
      range = next_range!
      return unless range

      handle_differences_in_verifiables(range)
    rescue StandardError => e
      log_error("Error while updating #{verification_state_table_name}", e)

      raise
    end

    private

    # @return [Range] the next range of a batch of records
    def next_range!
      Gitlab::Geo::BaseBatcher.new(replicable_model, verification_state_table_class, verification_state_model_key, key: batcher_key, batch_size: batch_size).next_range!
    end

    def batcher_key
      "verification_backfill:#{replicable_model.name.parameterize}"
    end

    # This method creates or deletes verification details records.
    #
    # It looks for replicable records that are eligible for verification (scoped
    # as `verifiables`) but whose corresponding verification details record doesn't
    # exist yet.
    # These would be replicable records that have recently become scoped as
    # `verifiables`, but were not so at the time of creation.
    # New replicable records will automatically create child records in the
    # verification details table, hence not created in this method.
    #
    # When a replicable record is no longer a part of the scope
    # `verifiables`, the corresponding verification state record needs to be deleted.
    # When a replicable record is deleted, the child record in the verification
    # details table is automatically removed, hence not deleted in this method.
    #
    # @return [Boolean] whether any rows needed to be inserted or deleted
    def handle_differences_in_verifiables(range)
      verifiable_ids = replicable_model.pluck_verifiable_ids_in_range(range) || []
      verification_details_ids = replicable_model.pluck_verification_details_ids_in_range(range) || []

      for_creation_ids = verifiable_ids - verification_details_ids
      for_deletion_ids = verification_details_ids - verifiable_ids

      create_verification_details(range, for_creation_ids)
      delete_verification_details(range, for_deletion_ids)

      [for_creation_ids, for_deletion_ids].flatten.compact.any?
    end

    def create_verification_details(range, for_creation_ids)
      replicable_model.find(for_creation_ids).map do |replicable|
        replicable.save_verification_details
      end

      log_created(range, for_creation_ids)
    end

    def delete_verification_details(range, for_deletion_ids)
      verification_state_table_class.delete(for_deletion_ids)

      log_deleted(range, for_deletion_ids)
    end

    def log_created(range, for_creation_ids)
      log_debug(
        "Created verification details for ",
        {
          replicable_model: replicable_model.name,
          start: range.first,
          finish: range.last,
          created: for_creation_ids
        }
      )
    end

    def log_deleted(range, for_deletion_ids)
      log_debug(
        "Deleted verification details for ",
        {
          replicable_model: replicable_model.name,
          start: range.first,
          finish: range.last,
          deleted: for_deletion_ids
        }
      )
    end
  end
end
