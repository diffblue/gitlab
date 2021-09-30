# frozen_string_literal: true

module Autocomplete
  class ProjectInvitedGroupsFinder
    attr_reader :current_user, :params

    # current_user - The User object of the user that wants to view the list of
    #                projects.
    #
    # params - A Hash containing additional parameters to set.
    #          The supported parameters are those supported by `Autocomplete::ProjectFinder`.
    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params
    end

    # rubocop: disable CodeReuse/Finder
    def execute
      project = ::Autocomplete::ProjectFinder
        .new(current_user, params)
        .execute

      return Group.none unless project

      invited_groups(project)
    end
    # rubocop: enable CodeReuse/Finder

    private

    def invited_groups(project)
      invited_groups = project.invited_groups

      Group.from_union([
        invited_groups.public_to_user(current_user),
        invited_groups.for_authorized_group_members(current_user)
      ])
    end
  end
end
