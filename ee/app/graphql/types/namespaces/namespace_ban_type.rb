# frozen_string_literal: true

module Types
  module Namespaces
    class NamespaceBanType < BaseObject # rubocop:disable Graphql/AuthorizeTypes(Authorization is done in resolver layer)
      graphql_name 'NamespaceBan'

      field :id,
        type: ::Types::GlobalIDType, null: false, description: 'Global ID of the namespace ban.'

      field :namespace, NamespaceType,
        null: false, description: 'Root namespace to which the ban applies.'

      field :user, UserType,
        null: false, description: 'User to which the namespace ban applies.'
    end
  end
end
