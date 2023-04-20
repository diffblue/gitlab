# frozen_string_literal: true

module Epics
  class UpdateCachedMetadataWorker
    include ApplicationWorker
    include ExclusiveLeaseGuard

    BATCH_SIZE = 100
    LEASE_TIMEOUT = 2.minutes

    data_consistency :always
    loggable_arguments 0
    idempotent!
    queue_namespace :epics
    feature_category :portfolio_management

    def perform(ids)
      locked_ids = []

      ::Epic.id_in(ids).find_each do |epic|
        # epic_id is set to assure epic-specific lease key
        @epic_id = epic.id

        lease = exclusive_lease.try_obtain

        if lease
          update_epic(epic)
        else
          locked_ids << epic.id
        end

      ensure
        release_lease(lease) if lease
      end

      return if locked_ids.empty?

      Gitlab::AppJsonLogger.error(message: "Following epic ids are locked, re-scheduling cache update: #{locked_ids}")
      self.class.perform_in(LEASE_TIMEOUT, locked_ids)
    end

    private

    def update_epic(epic)
      total_sums = epic.total_issue_weight_and_count
      epic.assign_attributes(total_sums)

      log_extra_metadata_on_done(:epic_id, epic.id)
      log_extra_metadata_on_done(:epic_iid, epic.iid)
      log_extra_metadata_on_done(:changed, epic.changed?)
      log_extra_metadata_on_done(:total_opened_issue_count, epic.total_opened_issue_count)
      log_extra_metadata_on_done(:total_closed_issue_count, epic.total_closed_issue_count)
      log_extra_metadata_on_done(:total_opened_issue_weight, epic.total_opened_issue_weight)
      log_extra_metadata_on_done(:total_closed_issue_weight, epic.total_closed_issue_weight)

      epic.save!(touch: false)
    rescue ActiveRecord::RecordInvalid
      logger.error(
        structured_payload(
          message: "skipping cache update, validation failed: #{epic.errors.full_messages.to_sentence}",
          epic_id: epic.id
        )
      )
    end

    def lease_key
      "#{self.class.name.underscore}-#{@epic_id}"
    end

    def lease_timeout
      LEASE_TIMEOUT
    end

    def exclusive_lease
      Gitlab::ExclusiveLease.new(lease_key, timeout: lease_timeout)
    end
  end
end
