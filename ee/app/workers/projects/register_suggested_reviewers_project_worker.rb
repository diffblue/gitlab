# frozen_string_literal: true

module Projects
  class RegisterSuggestedReviewersProjectWorker
    include ApplicationWorker

    data_consistency :always
    feature_category :workflow_automation
    urgency :low
    deduplicate :until_executed

    idempotent!

    # ::Projects::RegisterSuggestedReviewersProjectService makes an external RPC request
    worker_has_external_dependencies!

    def perform(project_id, user_id)
      project = Project.find_by_id(project_id)
      return unless project && project.suggested_reviewers_available? && project.suggested_reviewers_enabled

      user = User.find_by_id(user_id)
      return unless user

      result = ::Projects::RegisterSuggestedReviewersProjectService.new(project: project, current_user: user).execute

      return unless result && result[:status] == :success

      log_extra_metadata_on_done(:project_id, result[:project_id])
      log_extra_metadata_on_done(:registered_at, result[:registered_at])
    end
  end
end
