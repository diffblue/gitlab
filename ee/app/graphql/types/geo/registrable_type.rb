# frozen_string_literal: true

module Types
  module Geo
    class RegistrableType < BaseUnion
      RegistryTypeNotSupportedError = Class.new(StandardError)

      # Add new Geo registries here to use them as part of the RegistrableType union
      # registry class => registry type
      GEO_REGISTRY_TYPES = {
        ::Geo::CiSecureFileRegistry => Types::Geo::CiSecureFileRegistryType,
        ::Geo::ContainerRepositoryRegistry => Types::Geo::ContainerRepositoryRegistryType,
        ::Geo::DependencyProxyBlobRegistry => Types::Geo::DependencyProxyBlobRegistryType,
        ::Geo::DependencyProxyManifestRegistry => Types::Geo::DependencyProxyManifestRegistryType,
        ::Geo::DesignManagementRepositoryRegistry => Types::Geo::DesignManagementRepositoryRegistryType,
        ::Geo::JobArtifactRegistry => Types::Geo::JobArtifactRegistryType,
        ::Geo::LfsObjectRegistry => Types::Geo::LfsObjectRegistryType,
        ::Geo::MergeRequestDiffRegistry => Types::Geo::MergeRequestDiffRegistryType,
        ::Geo::PackageFileRegistry => Types::Geo::PackageFileRegistryType,
        ::Geo::PagesDeploymentRegistry => Types::Geo::PagesDeploymentRegistryType,
        ::Geo::PipelineArtifactRegistry => Types::Geo::PipelineArtifactRegistryType,
        ::Geo::ProjectWikiRepositoryRegistry => Types::Geo::ProjectWikiRepositoryRegistryType,
        ::Geo::SnippetRepositoryRegistry => Types::Geo::SnippetRepositoryRegistryType,
        ::Geo::TerraformStateVersionRegistry => Types::Geo::TerraformStateVersionRegistryType,
        ::Geo::UploadRegistry => Types::Geo::UploadRegistryType,
        ::Geo::GroupWikiRepositoryRegistry => Types::Geo::GroupWikiRepositoryRegistryType
      }.freeze

      possible_types(*GEO_REGISTRY_TYPES.values)

      def self.resolve_type(object, _)
        registry_type = GEO_REGISTRY_TYPES[object.class]

        raise RegistryTypeNotSupportedError unless registry_type

        registry_type
      end
    end
  end
end
