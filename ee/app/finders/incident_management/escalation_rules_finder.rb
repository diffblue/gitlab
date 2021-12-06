# frozen_string_literal: true

module IncidentManagement
  class EscalationRulesFinder
    # @param project [Project, Array<Project>, Integer(project_id), Array<Integer>, Project::ActiveRecord_Relation]
    #                Limit rules to within these projects
    # @param user [Project, Array<Project>, Integer(user_id), Array<Integer>, User::ActiveRecord_Relation]
    #             Limit rules to those which notify these users directly
    # @param include_removed [Boolean] Include rules which have been deleted in the UI but may correspond to existing pending escalations.
    # @param member [GroupMember, ProjectMember] A member which will be disambiguated into project/user params
    def initialize(user: nil, project: nil, include_removed: false, member: nil)
      @user = user
      @project = project
      @include_removed = include_removed

      disambiguate_member(member)
    end

    def execute
      rules = by_project(IncidentManagement::EscalationRule)
      rules = by_user(rules)

      with_removed(rules)
    end

    private

    attr_reader :member, :user, :project, :include_removed

    def by_project(rules)
      return rules unless project

      rules.for_project(project)
    end

    def by_user(rules)
      return rules unless user

      rules.for_user(user)
    end

    def with_removed(rules)
      return rules if include_removed

      rules.not_removed
    end

    def disambiguate_member(member)
      return unless member

      raise ArgumentError, 'Member param cannot be used with project or user params' if user || project
      raise ArgumentError, 'Member does not correspond to a user' unless member.user

      @user = member.user
      @project = member.source_type == 'Project' ? member.source_id : member.source.projects
    end
  end
end
