# frozen_string_literal: true

module Resolvers
  class EpicIssuesResolver < BaseResolver
    include CachingArrayResolver
    include SetsMaxPageSize

    type Types::EpicIssueType.connection_type, null: true

    alias_method :epic, :object

    def model_class
      ::Issue
    end

    def allowed?(issue)
      DeclarativePolicy.user_scope { issue.visible_to_user?(current_user) }
    end

    def query_input(**args)
      epic.id
    end

    def query_for(id)
      set_temp_limit_for(epic.group) # Can be removed with :performance_roadmap feature flag: https://gitlab.com/gitlab-org/gitlab/-/issues/337198

      ::Epic.related_issues(ids: id)
    end

    def preload
      { project: [:namespace, :project_feature] }
    end
  end
end
