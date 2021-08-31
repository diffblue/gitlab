# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['GeoNode'] do
  it { expect(described_class).to require_graphql_authorizations(:read_geo_node) }

  it 'has the expected fields' do
    expected_fields = %i[
      id primary enabled name url internal_url files_max_capacity
      repos_max_capacity verification_max_capacity
      container_repositories_max_capacity sync_object_storage
      selective_sync_type selective_sync_shards selective_sync_namespaces
      minimum_reverification_interval merge_request_diff_registries
      package_file_registries snippet_repository_registries
      terraform_state_version_registries group_wiki_repository_registries
      lfs_object_registries
      pipeline_artifact_registries
      pages_deployment_registries
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
