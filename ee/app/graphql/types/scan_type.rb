# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class ScanType < BaseObject
    present_using ::Security::ScanPresenter

    graphql_name 'Scan'
    description 'Represents the security scan information'

    authorize :read_scan

    field :name, GraphQL::Types::String, null: false, description: 'Name of the scan.'
    field :errors, [GraphQL::Types::String], null: false, description: 'List of errors.'
  end
end
