# frozen_string_literal: true

class RepositoryPushAuditEventWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :authentication_and_authorization

  # We have added no-op worker to drain queued sidekiq jobs.
  # TODO: We have follow up issue to completely remove this worker
  # https://gitlab.com/gitlab-org/gitlab/-/issues/360880
  def perform(changes, project_id, user_id)
    nil
  end
end
