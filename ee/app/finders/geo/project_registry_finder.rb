# frozen_string_literal: true

module Geo
  class ProjectRegistryFinder
    # Returns ProjectRegistry records where sync has never been attempted.
    #
    # Does not care about selective sync, because it considers the Registry
    # table to be the single source of truth. The contract is that other
    # processes need to ensure that the table only contains records that should
    # be synced.
    #
    # Any registries that this secondary has ever attempted to sync that currently need to be
    # resynced will be handled by other find methods (like
    # #find_registries_needs_sync_again)
    #
    # You can pass a list with `except_ids:` so you can exclude items you
    # already scheduled but haven't finished and aren't persisted to the database yet
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_ids ids that will be ignored from the query
    # rubocop:disable CodeReuse/ActiveRecord
    def find_registries_never_attempted_sync(batch_size:, except_ids: [])
      registry_class
        .find_registries_never_attempted_sync(batch_size: batch_size, except_ids: except_ids)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # rubocop:disable CodeReuse/ActiveRecord
    def find_registries_needs_sync_again(batch_size:, except_ids: [])
      registry_class
        .find_registries_needs_sync_again(batch_size: batch_size, except_ids: except_ids)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # rubocop:disable CodeReuse/ActiveRecord
    def find_project_ids_pending_verification(batch_size:, except_ids: [])
      registries =
        if ::Geo::ProjectWikiRepositoryReplicator.enabled?
          registry_class
            .repositories_checksummed_pending_verification
        else
          registry_class
            .from_union([
                          repositories_checksummed_pending_verification,
                          wikis_checksummed_pending_verification
                        ])
        end

      registries
        .model_id_not_in(except_ids)
        .limit(batch_size)
        .pluck_model_foreign_key
    end
    # rubocop:enable CodeReuse/ActiveRecord

    private

    def registry_class
      Geo::ProjectRegistry
    end

    # rubocop:disable CodeReuse/ActiveRecord
    def repositories_checksummed_pending_verification
      registry_class
        .repositories_checksummed_pending_verification
        .select(registry_class.arel_table[:project_id])
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # rubocop:disable CodeReuse/ActiveRecord
    def wikis_checksummed_pending_verification
      registry_class
        .wikis_checksummed_pending_verification
        .select(registry_class.arel_table[:project_id])
    end
    # rubocop:enable CodeReuse/ActiveRecord
  end
end
