# frozen_string_literal: true

class Groups::IssuesController < Groups::BulkUpdateController
  feature_category :team_planning
  urgency :low

  before_action :disable_query_limit!, only: :bulk_update

  private

  def disable_query_limit!
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/390722')
  end
end
