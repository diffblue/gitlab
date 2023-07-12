# frozen_string_literal: true

module EE
  module Types
    module Repository
      # rubocop: disable Graphql/AuthorizeTypes
      class CodeOwnerValidationType < ::Types::BaseObject
        graphql_name 'RepositoryCodeownerValidation'

        field :total, GraphQL::Types::Int,
          null: false,
          description: 'Total number of validation error in the file.'

        field :validation_errors, [::EE::Types::Repository::CodeOwnerErrorType],
          null: false,
          description: 'Specific lint error code.'
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end
