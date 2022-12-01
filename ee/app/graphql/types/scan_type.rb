# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class ScanType < BaseObject
    graphql_name 'Scan'
    description 'Represents the security scan information'

    present_using ::Security::ScanPresenter

    authorize :read_scan

    field :errors, [GraphQL::Types::String], null: false, description: 'List of errors.'
    field :name, GraphQL::Types::String, null: false, description: 'Name of the scan.'
    field :status, Types::ScanStatusEnum, null: false, description: 'Indicates the status of the scan.'
    field :warnings, [GraphQL::Types::String], null: false, description: 'List of warnings.'
  end
end
