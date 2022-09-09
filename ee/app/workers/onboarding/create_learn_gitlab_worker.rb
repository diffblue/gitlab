# frozen_string_literal: true

module Onboarding
  class CreateLearnGitlabWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    feature_category :onboarding
    urgency :high
    deduplicate :until_executed
    idempotent!

    def perform(template_path, project_name, parent_project_namespace_id, user_id)
      user = User.find(user_id)

      return if Onboarding::LearnGitlab.new(user).project.present?

      File.open(template_path) do |archive|
        ::Projects::GitlabProjectsImportService.new(
          user,
          namespace_id: parent_project_namespace_id,
          file: archive,
          name: project_name
        ).execute
      end

    rescue ActiveRecord::RecordNotFound => error
      logger.error(
        worker: self.class.name,
        namespace_id: parent_project_namespace_id,
        user_id: user_id,
        message: error.message
      )
    end
  end
end
