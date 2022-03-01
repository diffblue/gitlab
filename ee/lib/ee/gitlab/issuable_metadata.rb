# frozen_string_literal: true

module EE
  module Gitlab
    module IssuableMetadata
      extend ::Gitlab::Utils::Override

      override :metadata_for_issuable
      def metadata_for_issuable(id)
        super.tap do |data|
          blocking_count =
            grouped_blocking_issues_count.find do |issue_link|
              issue_link.blocking_issue_id == id
            end

          data.blocking_issues_count = blocking_count.try(:count).to_i
        end
      end

      def grouped_blocking_issues_count
        strong_memoize(:grouped_blocking_issues_count) do
          next ::IssueLink.none unless collection_type == 'Issue'

          ::IssueLink.blocking_issuables_for_collection(issuable_ids)
        end
      end
    end
  end
end
