# frozen_string_literal: true

module EpicIssues
  class ListService < IssuableLinks::ListService
    extend ::Gitlab::Utils::Override
    include ::Gitlab::Utils::StrongMemoize

    private

    def child_issuables
      strong_memoize(:child_issuables) do
        next [] unless issuable&.group&.feature_available?(:epics)

        issuable.issues_readable_by(current_user, preload: preload_for_collection)
      end
    end

    override :serializer
    def serializer
      LinkedEpicIssueSerializer
    end

    override :serializer_options
    def serializer_options
      child_issues_ids = child_issuables.map(&:id)

      blocked_issues_ids = ::IssueLink.blocked_issuable_ids(child_issues_ids)

      super.merge(blocked_issues_ids: blocked_issues_ids)
    end
  end
end
