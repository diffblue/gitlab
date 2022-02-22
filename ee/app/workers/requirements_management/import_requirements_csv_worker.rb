# frozen_string_literal: true

module RequirementsManagement
  class ImportRequirementsCsvWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include Gitlab::Utils::StrongMemoize

    idempotent!
    feature_category :requirements_management

    sidekiq_retries_exhausted do |job|
      Upload.find(job['args'][2]).destroy
    end

    def perform(current_user_id, project_id, upload_id)
      upload = Upload.find(upload_id)
      user = User.find(current_user_id)
      project = Project.find(project_id)

      RequirementsManagement::ImportCsvService.new(user, project, upload.retrieve_uploader).execute
      upload.destroy!
    rescue ActiveRecord::RecordNotFound
      # Resources have been removed, job should not be retried
    end
  end
end
