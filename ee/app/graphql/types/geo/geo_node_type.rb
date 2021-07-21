# frozen_string_literal: true

module Types
  module Geo
    class GeoNodeType < BaseObject
      graphql_name 'GeoNode'

      authorize :read_geo_node

      field :id, GraphQL::Types::ID, null: false, description: 'ID of this GeoNode.'
      field :primary, GraphQL::Types::Boolean, null: true, description: 'Indicates whether this Geo node is the primary.'
      field :enabled, GraphQL::Types::Boolean, null: true, description: 'Indicates whether this Geo node is enabled.'
      field :name, GraphQL::Types::String, null: true, description: 'The unique identifier for this Geo node.'
      field :url, GraphQL::Types::String, null: true, description: 'The user-facing URL for this Geo node.'
      field :internal_url, GraphQL::Types::String, null: true, description: 'The URL defined on the primary node that secondary nodes should use to contact it.'
      field :files_max_capacity, GraphQL::Types::Int, null: true, description: 'The maximum concurrency of LFS/attachment backfill for this secondary node.'
      field :repos_max_capacity, GraphQL::Types::Int, null: true, description: 'The maximum concurrency of repository backfill for this secondary node.'
      field :verification_max_capacity, GraphQL::Types::Int, null: true, description: 'The maximum concurrency of repository verification for this secondary node.'
      field :container_repositories_max_capacity, GraphQL::Types::Int, null: true, description: 'The maximum concurrency of container repository sync for this secondary node.'
      field :sync_object_storage, GraphQL::Types::Boolean, null: true, description: 'Indicates if this secondary node will replicate blobs in Object Storage.'
      field :selective_sync_type, GraphQL::Types::String, null: true, description: 'Indicates if syncing is limited to only specific groups, or shards.'
      field :selective_sync_shards, type: [GraphQL::Types::String], null: true, description: 'The repository storages whose projects should be synced, if `selective_sync_type` == `shards`.'
      field :selective_sync_namespaces, ::Types::NamespaceType.connection_type, null: true, method: :namespaces, description: 'The namespaces that should be synced, if `selective_sync_type` == `namespaces`.'
      field :minimum_reverification_interval, GraphQL::Types::Int, null: true, description: 'The interval (in days) in which the repository verification is valid. Once expired, it will be reverified.'
      field :merge_request_diff_registries, ::Types::Geo::MergeRequestDiffRegistryType.connection_type,
            null: true,
            resolver: ::Resolvers::Geo::MergeRequestDiffRegistriesResolver,
            description: 'Find merge request diff registries on this Geo node.'
      field :package_file_registries, ::Types::Geo::PackageFileRegistryType.connection_type,
            null: true,
            resolver: ::Resolvers::Geo::PackageFileRegistriesResolver,
            description: 'Package file registries of the GeoNode.'
      field :snippet_repository_registries, ::Types::Geo::SnippetRepositoryRegistryType.connection_type,
            null: true,
            resolver: ::Resolvers::Geo::SnippetRepositoryRegistriesResolver,
            description: 'Find snippet repository registries on this Geo node.'
      field :terraform_state_version_registries, ::Types::Geo::TerraformStateVersionRegistryType.connection_type,
            null: true,
            resolver: ::Resolvers::Geo::TerraformStateVersionRegistriesResolver,
            description: 'Find terraform state version registries on this Geo node.'
      field :group_wiki_repository_registries, ::Types::Geo::GroupWikiRepositoryRegistryType.connection_type,
            null: true,
            resolver: ::Resolvers::Geo::GroupWikiRepositoryRegistriesResolver,
            description: 'Find group wiki repository registries on this Geo node.'
      field :lfs_object_registries, ::Types::Geo::LfsObjectRegistryType.connection_type,
            null: true,
            resolver: ::Resolvers::Geo::LfsObjectRegistriesResolver,
            description: 'Find LFS object registries on this Geo node.'
      field :pipeline_artifact_registries, ::Types::Geo::PipelineArtifactRegistryType.connection_type,
            null: true,
            resolver: ::Resolvers::Geo::PipelineArtifactRegistriesResolver,
            description: 'Find pipeline artifact registries on this Geo node.'
    end
  end
end
