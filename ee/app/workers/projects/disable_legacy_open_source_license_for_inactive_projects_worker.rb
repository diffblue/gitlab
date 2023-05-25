# frozen_string_literal: true

module Projects
  class DisableLegacyOpenSourceLicenseForInactiveProjectsWorker
    include ApplicationWorker

    # This worker does not perform work scoped to a context
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    idempotent!
    data_consistency :sticky
    feature_category :groups_and_projects
    urgency :low

    sidekiq_options retry: 3

    def perform
      Projects::DisableLegacyInactiveProjectsService.new.execute
    end
  end
end
