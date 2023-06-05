# frozen_string_literal: true

module Types
  module Security
    # rubocop: disable Graphql/AuthorizeTypes (The resolver authorizes the request)
    class FindingReportsComparerType < BaseObject
      graphql_name 'FindingReportsComparer'

      description 'Represents security reports comparison for vulnerability findings.'

      field :status,
        type: FindingReportsComparer::StatusEnum,
        null: true,
        description: 'Comparison status.'

      field :status_reason,
        type: GraphQL::Types::String,
        null: true,
        description: 'Text explaining the status.'

      field :report,
        type: FindingReportsComparer::ReportType,
        null: true,
        alpha: { milestone: '16.1' },
        hash_key: 'data',
        description: 'Compared security report.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
