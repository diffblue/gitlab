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

    def perform(_template_path, _project_name, _parent_project_namespace_id, _user_id)
      # no-op https://docs.gitlab.com/ee/development/sidekiq/compatibility_across_updates.html#removing-worker-classes
    end
  end
end
