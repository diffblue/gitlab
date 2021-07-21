# frozen_string_literal: true

module StatusPage
  class PublishWorker
    include ApplicationWorker

    data_consistency :always
    include Gitlab::Utils::StrongMemoize

    sidekiq_options retry: 5

    feature_category :incident_management
    worker_has_external_dependencies!
    idempotent!

    def perform(user_id, project_id, issue_id)
      @user_id = user_id
      @project_id = project_id
      @issue_id = issue_id

      return unless user && project

      publish
    end

    private

    attr_reader :user_id, :project_id, :issue_id

    def publish
      result = PublishService
        .new(user: user, project: project, issue_id: issue_id)
        .execute

      log_info(result.message) if result.error?
    end

    def user
      strong_memoize(:user) { User.find_by_id(user_id) }
    end

    def project
      strong_memoize(:project) { Project.find_by_id(project_id) }
    end

    def log_info(message)
      logger.info(structured_payload(message: message))
    end
  end
end
