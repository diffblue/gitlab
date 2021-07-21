# frozen_string_literal: true

module Types
  module Geo
    # rubocop:disable Graphql/AuthorizeTypes because it is included
    class PipelineArtifactRegistryType < BaseObject
      include ::Types::Geo::RegistryType

      graphql_name 'PipelineArtifactRegistry'
      description 'Represents the Geo sync and verification state of a pipeline artifact'

      field :pipeline_artifact_id, GraphQL::Types::ID, null: false, description: 'ID of the pipeline artifact.'
    end
  end
end
