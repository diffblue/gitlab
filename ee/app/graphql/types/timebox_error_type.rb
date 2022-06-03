# frozen_string_literal: true
# rubocop: disable Graphql/AuthorizeTypes

module Types
  class TimeboxErrorType < BaseObject
    graphql_name 'TimeboxReportError'
    description 'Explains why we could not generate a timebox report.'

    field :code, ::Types::TimeboxErrorReasonEnum,
          null: true,
          description: 'Machine readable code, categorizing the error.'
    field :message, ::GraphQL::Types::String,
          null: true,
          description: 'Human readable message explaining what happened.'
  end
end
