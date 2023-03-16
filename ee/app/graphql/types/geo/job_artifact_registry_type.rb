# frozen_string_literal: true

module Types
  module Geo
    # rubocop:disable Graphql/AuthorizeTypes because it is included
    class JobArtifactRegistryType < BaseObject
      graphql_name 'JobArtifactRegistry'
      description 'Represents the Geo replication and verification state of a job_artifact.'

      include ::Types::Geo::RegistryType

      field :artifact_id, GraphQL::Types::ID, null: false, description: 'ID of the Job Artifact.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
