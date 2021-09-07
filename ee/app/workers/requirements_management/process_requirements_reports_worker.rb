# frozen_string_literal: true

module RequirementsManagement
  class ProcessRequirementsReportsWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    feature_category :requirements_management
    idempotent!

    def perform(build_id)
      ::Ci::Build.find_by_id(build_id).try do |build|
        RequirementsManagement::ProcessTestReportsService.new(build).execute
      end
    rescue Gitlab::Access::AccessDeniedError
      Gitlab::AppLogger.error(
        "RequirementsManagement::ProcessRequirementsReportsWorker: Insufficient permissions to " \
        "create tests reports for build #{build_id}, skipping"
      )
    end
  end
end
