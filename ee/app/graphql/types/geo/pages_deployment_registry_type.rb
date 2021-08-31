# frozen_string_literal: true

module Types
  module Geo
    # rubocop:disable Graphql/AuthorizeTypes because it is included
    class PagesDeploymentRegistryType < BaseObject
      include ::Types::Geo::RegistryType

      graphql_name 'PagesDeploymentRegistry'
      description 'Represents the Geo replication and verification state of a pages_deployment'

      field :pages_deployment_id, GraphQL::Types::ID, null: false, description: 'ID of the Pages Deployment.'
    end
  end
end
