# frozen_string_literal: true

module Arkose
  class BlockedUsersReportWorker
    include ApplicationWorker

    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    idempotent!
    data_consistency :always
    feature_category :system_access

    def perform
      return unless ::Feature.enabled?(:arkose_labs_login_challenge)

      ::Arkose::BlockedUsersReportService.new.execute
    end
  end
end
