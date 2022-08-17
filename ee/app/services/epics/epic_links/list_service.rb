# frozen_string_literal: true

module Epics
  module EpicLinks
    class ListService < IssuableLinks::ListService
      extend ::Gitlab::Utils::Override

      private

      def child_issuables
        return [] unless issuable&.group&.feature_available?(:epics)

        EpicsFinder.new(current_user, parent_id: issuable.id,
                                      group_id: issuable.group.id,
                                      sort: 'relative_position').execute
      end

      override :serializer
      def serializer
        LinkedEpicSerializer
      end
    end
  end
end
