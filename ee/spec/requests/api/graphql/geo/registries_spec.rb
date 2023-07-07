# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Gets registries', feature_category: :geo_replication do
  it_behaves_like 'gets registries for', {
    field_name: 'mergeRequestDiffRegistries',
    registry_class_name: 'MergeRequestDiffRegistry',
    registry_factory: :geo_merge_request_diff_registry,
    registry_foreign_key_field_name: 'mergeRequestDiffId'
  }

  it_behaves_like 'gets registries for', {
    field_name: 'packageFileRegistries',
    registry_class_name: 'PackageFileRegistry',
    registry_factory: :geo_package_file_registry,
    registry_foreign_key_field_name: 'packageFileId'
  }

  it_behaves_like 'gets registries for', {
    field_name: 'snippetRepositoryRegistries',
    registry_class_name: 'SnippetRepositoryRegistry',
    registry_factory: :geo_snippet_repository_registry,
    registry_foreign_key_field_name: 'snippetRepositoryId'
  }

  it_behaves_like 'gets registries for', {
    field_name: 'terraformStateVersionRegistries',
    registry_class_name: 'TerraformStateVersionRegistry',
    registry_factory: :geo_terraform_state_version_registry,
    registry_foreign_key_field_name: 'terraformStateVersionId'
  }

  it_behaves_like 'gets registries for', {
    field_name: 'groupWikiRepositoryRegistries',
    registry_class_name: 'GroupWikiRepositoryRegistry',
    registry_factory: :geo_group_wiki_repository_registry,
    registry_foreign_key_field_name: 'groupWikiRepositoryId'
  }

  it_behaves_like 'gets registries for', {
    field_name: 'pipelineArtifactRegistries',
    registry_class_name: 'PipelineArtifactRegistry',
    registry_factory: :geo_pipeline_artifact_registry,
    registry_foreign_key_field_name: 'pipelineArtifactId'
  }

  it_behaves_like 'gets registries for', {
    field_name: 'pagesDeploymentRegistries',
    registry_class_name: 'PagesDeploymentRegistry',
    registry_factory: :geo_pages_deployment_registry,
    registry_foreign_key_field_name: 'pagesDeploymentId'
  }

  it_behaves_like 'gets registries for', {
    field_name: 'uploadRegistries',
    registry_class_name: 'UploadRegistry',
    registry_factory: :geo_upload_registry,
    registry_foreign_key_field_name: 'fileId'
  }

  it_behaves_like 'gets registries for', {
    field_name: 'jobArtifactRegistries',
    registry_class_name: 'JobArtifactRegistry',
    registry_factory: :geo_job_artifact_registry,
    registry_foreign_key_field_name: 'artifactId'
  }

  it_behaves_like 'gets registries for', {
    field_name: 'ciSecureFileRegistries',
    registry_class_name: 'CiSecureFileRegistry',
    registry_factory: :geo_ci_secure_file_registry,
    registry_foreign_key_field_name: 'ciSecureFileId'
  }

  it_behaves_like 'gets registries for', {
    field_name: 'dependencyProxyBlobRegistries',
    registry_class_name: 'DependencyProxyBlobRegistry',
    registry_factory: :geo_dependency_proxy_blob_registry,
    registry_foreign_key_field_name: 'dependencyProxyBlobId'
  }

  it_behaves_like 'gets registries for', {
    field_name: 'dependencyProxyManifestRegistries',
    registry_class_name: 'DependencyProxyManifestRegistry',
    registry_factory: :geo_dependency_proxy_manifest_registry,
    registry_foreign_key_field_name: 'dependencyProxyManifestId'
  }

  it_behaves_like 'gets registries for', {
    field_name: 'projectWikiRepositoryRegistries',
    registry_class_name: 'ProjectWikiRepositoryRegistry',
    registry_factory: :geo_project_wiki_repository_registry,
    registry_foreign_key_field_name: 'projectWikiRepositoryId'
  }

  it_behaves_like 'gets registries for', {
    field_name: 'designManagementRepositoryRegistries',
    registry_class_name: 'DesignManagementRepositoryRegistry',
    registry_factory: :geo_design_management_repository_registry,
    registry_foreign_key_field_name: 'designManagementRepositoryId'
  }

  it_behaves_like 'gets registries for', {
    field_name: 'projectRepositoryRegistries',
    registry_class_name: 'ProjectRepositoryRegistry',
    registry_factory: :geo_project_repository_registry,
    registry_foreign_key_field_name: 'projectId'
  }
end
