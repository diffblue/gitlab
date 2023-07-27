# frozen_string_literal: true

RSpec.shared_context 'with geo registries shared context' do
  using RSpec::Parameterized::TableSyntax

  where(:registry_class, :registry_type, :registry_factory) do
    # rubocop:disable Layout/LineLength
    Geo::CiSecureFileRegistry               | Types::Geo::CiSecureFileRegistryType               | :geo_ci_secure_file_registry
    Geo::ContainerRepositoryRegistry        | Types::Geo::ContainerRepositoryRegistryType        | :geo_container_repository_registry
    Geo::DependencyProxyBlobRegistry        | Types::Geo::DependencyProxyBlobRegistryType        | :geo_dependency_proxy_blob_registry
    Geo::DependencyProxyManifestRegistry    | Types::Geo::DependencyProxyManifestRegistryType    | :geo_dependency_proxy_manifest_registry
    Geo::DesignManagementRepositoryRegistry | Types::Geo::DesignManagementRepositoryRegistryType | :geo_design_management_repository_registry
    Geo::JobArtifactRegistry                | Types::Geo::JobArtifactRegistryType                | :geo_job_artifact_registry
    Geo::LfsObjectRegistry                  | Types::Geo::LfsObjectRegistryType                  | :geo_lfs_object_registry
    Geo::MergeRequestDiffRegistry           | Types::Geo::MergeRequestDiffRegistryType           | :geo_merge_request_diff_registry
    Geo::PackageFileRegistry                | Types::Geo::PackageFileRegistryType                | :geo_package_file_registry
    Geo::PagesDeploymentRegistry            | Types::Geo::PagesDeploymentRegistryType            | :geo_pages_deployment_registry
    Geo::PipelineArtifactRegistry           | Types::Geo::PipelineArtifactRegistryType           | :geo_pipeline_artifact_registry
    Geo::ProjectWikiRepositoryRegistry      | Types::Geo::ProjectWikiRepositoryRegistryType      | :geo_project_wiki_repository_registry
    Geo::SnippetRepositoryRegistry          | Types::Geo::SnippetRepositoryRegistryType          | :geo_snippet_repository_registry
    Geo::TerraformStateVersionRegistry      | Types::Geo::TerraformStateVersionRegistryType      | :geo_terraform_state_version_registry
    Geo::UploadRegistry                     | Types::Geo::UploadRegistryType                     | :geo_upload_registry
    Geo::GroupWikiRepositoryRegistry        | Types::Geo::GroupWikiRepositoryRegistryType        | :geo_group_wiki_repository_registry
    # rubocop:enable Layout/LineLength
  end
end
