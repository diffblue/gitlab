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
        Epics::CrossHierarchyChildrenFinder.new(
          current_user,
          { parent: issuable, sort: 'relative_position' }
        ).execute(preload: true)
      end
    end
  end
end
