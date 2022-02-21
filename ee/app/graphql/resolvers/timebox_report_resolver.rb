# frozen_string_literal: true

module Resolvers
  class TimeboxReportResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    type Types::TimeboxReportType, null: true

    argument :full_path, GraphQL::Types::String,
             required: false,
             description: 'Full path of the project or group used as a scope for report. For example, `gitlab-org` or `gitlab-org/gitlab`.'

    alias_method :timebox, :object

    def resolve(**args)
      find_and_authorize_scope!(args)
      project_scopes = projects_in_scope(args)

      response = TimeboxReportService.new(timebox, project_scopes).execute

      raise GraphQL::ExecutionError, response.message if response.error?

      response.payload
    end

    private

    def find_and_authorize_scope!(args)
      return unless args[:full_path].present?

      @group_scope = Group.find_by_full_path(args[:full_path])
      @project_scope = Project.find_by_full_path(args[:full_path]) if @group_scope.nil?

      raise_resource_not_available_error! if @group_scope.nil? && @project_scope.nil?

      authorize_scope!
    end

    def authorize_scope!
      if @project_scope
        Ability.allowed?(context[:current_user], :read_issue, @project_scope) || raise_resource_not_available_error!
      elsif @group_scope
        Ability.allowed?(context[:current_user], :read_group, @group_scope) || raise_resource_not_available_error!
      end
    end

    def projects_in_scope(args)
      if @project_scope
        Project.id_in(@project_scope.id)
      elsif @group_scope
        Project.for_group_and_its_subgroups(@group_scope)
      end
    end
  end
end
