# frozen_string_literal: true

module Epics
  module EpicLinks
    class ListService < IssuableLinks::ListService
      extend ::Gitlab::Utils::Override

      private

      def child_issuables
        return [] unless issuable&.group&.feature_available?(:epics)

        find_children
      end

      override :serializer
      def serializer
        LinkedEpicSerializer
      end

      def find_children
        params = { sort: 'relative_position' }

        finder = if ::Feature.enabled?(:child_epics_from_different_hierarchies, issuable&.group)
                   Epics::CrossHierarchyChildrenFinder.new(
                     current_user,
                     params.merge(parent: issuable)
                   )
                 else
                   EpicsFinder.new(
                     current_user,
                     params.merge(parent_id: issuable.id, group_id: issuable.group.id)
                   )
                 end

        finder.execute
      end
    end
  end
end
