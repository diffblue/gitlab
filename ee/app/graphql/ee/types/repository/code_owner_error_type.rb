# frozen_string_literal: true

module EE
  module Types
    module Repository
      # rubocop: disable Graphql/AuthorizeTypes
      class CodeOwnerErrorType < ::Types::BaseObject
        graphql_name 'RepositoryCodeownerError'

        field :code, GraphQL::Types::String,
          null: false,
          description: 'Linting error code.'

        field :lines, [GraphQL::Types::Int],
          null: false,
          description: 'Lines where the error occurred.'
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end
