# frozen_string_literal: true

module Geo
  # Service that marks registries as pending in batches
  # to be resynchronized by Geo periodic workers later
  class BulkMarkPendingService < BaseBulkUpdateService
    extend Gitlab::Utils::Override

    private

    # Method that sets the name of the new registry's state
    # used by the Redis key cursor prefix
    override :bulk_mark_update_name
    def bulk_mark_update_name
      'pending'
    end

    # Method that sets the registry's attributes that need update and their new values
    override :attributes_to_update
    def attributes_to_update
      {
        state: registry_class.state_value(:pending),
        last_synced_at: nil
      }
    end

    # Method that sets the registries that need to be updated
    override :pending_to_update_relation
    def pending_to_update_relation
      registry_class.not_pending
    end
  end
end
