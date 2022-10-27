# frozen_string_literal: true

# EpicsFinder
#
# Used to find and filter all ancestors for an epic.
# Returns list of all epic's ancestors from the closest to root epic.
#
# WARNING: the result relation is not filtered by user's accessibility (because
# we want to return query/AR relation so it can be used with looksahead) and
# permission filtering of accessible epics needs to be done on upper layer

module Epics
  class CrossHierarchyAncestorsFinder < IssuableFinder
    include Findable
    extend ::Gitlab::Utils::Override

    def execute
      return Epic.none unless Ability.allowed?(current_user, :read_epic, child)

      filter_and_search(init_collection)
    end

    private

    override :init_collection
    def init_collection
      child.ancestors(hierarchy_order: :asc)
    end

    override :milestone_groups
    def milestone_groups
      ::Group.id_in(child.ancestors(hierarchy_order: nil).select(:group_id)) # rubocop: disable CodeReuse/ActiveRecord
    end

    def child
      raise ArgumentError, 'child argument is missing' unless params[:child]

      params[:child]
    end
  end
end
