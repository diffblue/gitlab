# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['GeoNode'], feature_category: :geo_replication do
  it { expect(described_class).to require_graphql_authorizations(:read_geo_node) }

  it 'has the expected fields' do
    expected_fields = %i[
      id
      primary
      enabled
      name
      url
      internal_url
      files_max_capacity
      repos_max_capacity
      verification_max_capacity
      container_repositories_max_capacity
      sync_object_storage
      selective_sync_type
      selective_sync_shards
      selective_sync_namespaces
      minimum_reverification_interval
      ci_secure_file_registries
      container_repository_registries
      dependency_proxy_blob_registries
      dependency_proxy_manifest_registries
      design_management_repository_registries
      group_wiki_repository_registries
      job_artifact_registries
      lfs_object_registries
      merge_request_diff_registries
      package_file_registries
      pages_deployment_registries
      pipeline_artifact_registries
      project_wiki_repository_registries
      snippet_repository_registries
      terraform_state_version_registries
      upload_registries
      project_repository_registries
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
