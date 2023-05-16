# frozen_string_literal: true

module Types
  module Geo
    # rubocop:disable Graphql/AuthorizeTypes because it is included
    class PagesDeploymentRegistryType < BaseObject
      graphql_name 'PagesDeploymentRegistry'
      description 'Represents the Geo replication and verification state of a pages_deployment'

      include ::Types::Geo::RegistryType

      field :pages_deployment_id, GraphQL::Types::ID, null: false, description: 'ID of the Pages Deployment.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
