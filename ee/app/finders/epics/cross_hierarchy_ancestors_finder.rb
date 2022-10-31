# frozen_string_literal: true

# CrossHierarchyAncestorsFinder
#
# Used to find and filter all ancestors for an epic.
# Returns list of all epic's ancestors from the closest to root epic,
# any ancestors not accessible to the user are filtered out.

module Epics
  class CrossHierarchyAncestorsFinder < IssuableFinder
    include Findable
    include WithAccessCheck
    extend ::Gitlab::Utils::Override

    def execute
      return Epic.none unless Ability.allowed?(current_user, :read_epic, child)
      return Epic.none unless child.parent_id

      filter_and_search(epics_with_read_access)
    end

    private

    override :epics_collection
    def epics_collection
      child.ancestors(hierarchy_order: :asc)
    end

    def epics_collection_for_groups
      child.ancestors(hierarchy_order: nil)
    end

    override :milestone_groups
    def milestone_groups
      permissioned_groups
    end

    override :base_epic
    def base_epic
      child
    end

    def child
      raise ArgumentError, 'child argument is missing' unless params[:child]

      params[:child]
    end
  end
end
