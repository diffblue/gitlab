# frozen_string_literal: true
module Types
  class PathLockType < BaseObject # rubocop:disable Graphql/AuthorizeTypes
    graphql_name 'PathLock'
    description 'Represents a file or directory in the project repository that has been locked.'

    field :id, ::Types::GlobalIDType[PathLock], null: false,
          description: 'ID of the path lock.'

    field :path, GraphQL::Types::String, null: true,
          description: 'The locked path.'

    field :user, ::Types::UserType, null: true,
          description: 'The user that has locked this path.'
  end
end
