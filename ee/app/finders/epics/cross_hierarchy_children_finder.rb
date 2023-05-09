# frozen_string_literal: true

module Epics
  class CrossHierarchyChildrenFinder < IssuableFinder
    include Findable
    include WithAccessCheck
    extend ::Gitlab::Utils::Override

    def execute(preload: false)
      return Epic.none unless Ability.allowed?(current_user, :read_epic, parent)

      items = filter_and_search(epics_with_read_access(preload: preload))

      sort(items)
    end

    private

    def epics_collection
      Epic.in_parents(parent)
    end
    alias_method :epics_collection_for_groups, :epics_collection

    def parent
      raise ArgumentError, 'parent argument is missing' unless params[:parent]

      params[:parent]
    end

    def base_epic
      parent
    end

    override :milestone_groups
    def milestone_groups
      permissioned_groups
    end
  end
end
