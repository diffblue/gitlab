# frozen_string_literal: true

class StoreSecurityScansWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include SecurityScansQueue

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(*)
    # no-op
    # This worker has been deprecated and will be removed with next release.
    # New worker to do the same job is, `Security::StoreScansWorker`,
    # We will save all the security scans and findings here
    # as well as solve the deduplication thingy.
  end
end
