# frozen_string_literal: true

module Epics
  module RelatedEpicLinks
    class ListService < IssuableLinks::ListService
      extend ::Gitlab::Utils::Override

      private

      def child_issuables
        issuable.related_epics(current_user, preload: preload_for_collection)
      end

      override :serializer
      def serializer
        Epics::RelatedEpicSerializer
      end

      override :preload_for_collection
      def preload_for_collection
        [group: [:saml_provider, :route]]
      end
    end
  end
end
