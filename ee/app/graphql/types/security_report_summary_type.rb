# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class SecurityReportSummaryType < BaseObject
    graphql_name 'SecurityReportSummary'
    description 'Represents summary of a security report'

    ::Enums::Vulnerability.report_types.keys.each do |report_type|
      field report_type,
            ::Types::SecurityReportSummarySectionType,
            null: true,
            description: "Aggregated counts for the `#{report_type}` scan"
    end
  end
end
