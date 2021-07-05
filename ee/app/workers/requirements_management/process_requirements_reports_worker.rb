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
    end
  end
end
