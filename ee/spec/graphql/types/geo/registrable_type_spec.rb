# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Geo::RegistrableType, feature_category: :geo_replication do
  describe '.resolve_type' do
    context 'when resolving a supported registry type' do
      using RSpec::Parameterized::TableSyntax

      where(:registry_type, :registry_factory) do
        Types::Geo::CiSecureFileRegistryType            | :geo_ci_secure_file_registry
        Types::Geo::ContainerRepositoryRegistryType     | :geo_container_repository_registry
        Types::Geo::DependencyProxyBlobRegistryType     | :geo_dependency_proxy_blob_registry
        Types::Geo::DependencyProxyManifestRegistryType | :geo_dependency_proxy_manifest_registry
        Types::Geo::JobArtifactRegistryType             | :geo_job_artifact_registry
        Types::Geo::LfsObjectRegistryType               | :geo_lfs_object_registry
        Types::Geo::MergeRequestDiffRegistryType        | :geo_merge_request_diff_registry
        Types::Geo::PackageFileRegistryType             | :geo_package_file_registry
        Types::Geo::PagesDeploymentRegistryType         | :geo_pages_deployment_registry
        Types::Geo::PipelineArtifactRegistryType        | :geo_pipeline_artifact_registry
        Types::Geo::ProjectWikiRepositoryRegistryType   | :geo_project_wiki_repository_registry
        Types::Geo::SnippetRepositoryRegistryType       | :geo_snippet_repository_registry
        Types::Geo::TerraformStateVersionRegistryType   | :geo_terraform_state_version_registry
        Types::Geo::UploadRegistryType                  | :geo_upload_registry
      end

      with_them do
        it 'resolves to a Geo registry type' do
          resolved_type = described_class.resolve_type(build(registry_factory), {})

          expect(resolved_type).to be(registry_type)
        end
      end
    end

    context 'when resolving an unsupported registry type' do
      it 'raises a TypeNotSupportedError for string object' do
        expect do
          described_class.resolve_type('unrelated object', {})
        end.to raise_error(Types::Geo::RegistrableType::RegistryTypeNotSupportedError)
      end

      it 'raises a TypeNotSupportedError for nil object' do
        expect do
          described_class.resolve_type(nil, {})
        end.to raise_error(Types::Geo::RegistrableType::RegistryTypeNotSupportedError)
      end

      it 'raises a TypeNotSupportedError for other registry type' do
        expect do
          described_class.resolve_type(build(:geo_design_registry), {})
        end.to raise_error(Types::Geo::RegistrableType::RegistryTypeNotSupportedError)
      end
    end
  end
end
