# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['GeoRegistryClass'], feature_category: :geo_replication do
  let(:registry_classes) do
    %w[
      CONTAINER_REPOSITORY_REGISTRY
      JOB_ARTIFACT_REGISTRY
      LFS_OBJECT_REGISTRY
      MERGE_REQUEST_DIFF_REGISTRY
      PACKAGE_FILE_REGISTRY
      PIPELINE_ARTIFACT_REGISTRY
      TERRAFORM_STATE_VERSION_REGISTRY
      UPLOAD_REGISTRY
      SNIPPET_REPOSITORY_REGISTRY
      PAGES_DEPLOYMENT_REGISTRY
      CI_SECURE_FILE_REGISTRY
      DEPENDENCY_PROXY_BLOB_REGISTRY
      DEPENDENCY_PROXY_MANIFEST_REGISTRY
      PROJECT_WIKI_REPOSITORY_REGISTRY
      DESIGN_MANAGEMENT_REPOSITORY_REGISTRY
      PROJECT_REPOSITORY_REGISTRY
      GROUP_WIKI_REPOSITORY_REGISTRY
    ]
  end

  it { expect(described_class.graphql_name).to eq('GeoRegistryClass') }

  it 'exposes the correct registry actions' do
    expect(described_class.values.keys).to match_array(registry_classes)
  end
end
