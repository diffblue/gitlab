# frozen_string_literal: true

module Types
  module Geo
    # rubocop:disable Graphql/AuthorizeTypes because it is included
    class PipelineArtifactRegistryType < BaseObject
      graphql_name 'PipelineArtifactRegistry'
      description 'Represents the Geo sync and verification state of a pipeline artifact'

      include ::Types::Geo::RegistryType

      field :pipeline_artifact_id, GraphQL::Types::ID, null: false, description: 'ID of the pipeline artifact.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
