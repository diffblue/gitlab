# frozen_string_literal: true

module Geo
  # Service that marks registries pending to verify in batches
  # to be verified by Geo periodic workers later
  class BulkMarkVerificationPendingService < BaseBulkUpdateService
    extend Gitlab::Utils::Override

    private

    # Method that sets the name of the new registry's verification_state
    # used by the Redis key cursor prefix
    override :bulk_mark_update_name
    def bulk_mark_update_name
      'verification_pending'
    end

    # Method that sets the registry's attributes that need update and their new values
    override :attributes_to_update
    def attributes_to_update
      { verification_state: registry_class.verification_state_value(:verification_pending) }
    end

    # Method that sets the registries that need to be updated
    override :pending_to_update_relation
    def pending_to_update_relation
      registry_class.verification_not_pending
    end
  end
end
