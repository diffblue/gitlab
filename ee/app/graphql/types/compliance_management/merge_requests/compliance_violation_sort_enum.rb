# frozen_string_literal: true

module Types
  module ComplianceManagement
    module MergeRequests
      class ComplianceViolationSortEnum < BaseEnum
        graphql_name 'ComplianceViolationSort'
        description 'Compliance violation sort values.'

        value 'SEVERITY_LEVEL_DESC', 'Severity in descending order, further sorted by ID in descending order.'
        value 'SEVERITY_LEVEL_ASC', 'Severity in ascending order, further sorted by ID in ascending order.'

        value 'VIOLATION_REASON_DESC', 'Violation reason in descending order, further sorted by ID in descending order.'
        value 'VIOLATION_REASON_ASC', 'Violation reason in ascending order, further sorted by ID in ascending order.'

        value 'MERGE_REQUEST_TITLE_DESC', 'Merge request title in descending order, further sorted by ID in descending order.'
        value 'MERGE_REQUEST_TITLE_ASC', 'Merge request title in ascending order, further sorted by ID in ascending order.'

        value 'MERGED_AT_DESC', 'Date merged in descending order, further sorted by ID in descending order.'
        value 'MERGED_AT_ASC', 'Date merged in ascending order, further sorted by ID in ascending order.'
      end
    end
  end
end
