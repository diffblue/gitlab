# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class SecurityReportSummarySectionType < BaseObject
    graphql_name 'SecurityReportSummarySection'
    description 'Represents a section of a summary of a security report'

    field :vulnerabilities_count, GraphQL::Types::Int, null: true, description: 'Total number of vulnerabilities.'
    field :scanned_resources_count, GraphQL::Types::Int, null: true, description: 'Total number of scanned resources.'
    field :scanned_resources, ::Types::ScannedResourceType.connection_type, null: true, description: 'A list of the first 20 scanned resources.'
    field :scanned_resources_csv_path, GraphQL::Types::String, null: true, description: 'Path to download all the scanned resources in CSV format.'
    field :scans, ::Types::ScanType.connection_type, null: false, description: 'List of security scans ran for the type.'
  end
end
