# frozen_string_literal: true

module Types
  module Geo
    # rubocop:disable Graphql/AuthorizeTypes because it is included
    class TerraformStateVersionRegistryType < BaseObject
      include ::Types::Geo::RegistryType

      graphql_name 'TerraformStateVersionRegistry'
      description 'Represents the Geo sync and verification state of a terraform state version'

      field :terraform_state_version_id, GraphQL::Types::ID, null: false, description: 'ID of the terraform state version.'
    end
  end
end
