# frozen_string_literal: true

class MergeRequestResetApprovalsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :source_code_management
  urgency :high
  worker_resource_boundary :cpu
  loggable_arguments 2, 3

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(project_id, user_id, ref, newrev)
    project = Project.find_by(id: project_id)
    return unless project

    user = User.find_by(id: user_id)
    return unless user

    MergeRequests::ResetApprovalsService.new(project: project, current_user: user).execute(ref, newrev)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
