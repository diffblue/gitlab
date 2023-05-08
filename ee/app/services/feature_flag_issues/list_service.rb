# frozen_string_literal: true

module FeatureFlagIssues
  class ListService < IssuableLinks::ListService
    extend ::Gitlab::Utils::Override

    private

    def child_issuables
      issuable.related_issues(current_user, preload: preload_for_collection)
    end

    override :serializer
    def serializer
      LinkedFeatureFlagIssueSerializer
    end

    override :preload_for_collection
    def preload_for_collection
      super + [:work_item_type, :namespace]
    end
  end
end
