# frozen_string_literal: true

module Security
  class OrchestrationConfigurationCreateBotWorker
    include ApplicationWorker

    feature_category :security_policy_management

    data_consistency :sticky

    idempotent!

    def perform(project_id, current_user_id)
      project = Project.find_by_id(project_id)

      return if project.nil?

      skip_authorization = current_user_id.nil?
      current_user = User.find_by_id(current_user_id) if current_user_id

      return if !skip_authorization && current_user.nil?

      Security::Orchestration::CreateBotService
        .new(project, current_user, skip_authorization: skip_authorization)
        .execute
    rescue Gitlab::Access::AccessDeniedError
      # Rescue errors to avoid worker retry
    end
  end
end
