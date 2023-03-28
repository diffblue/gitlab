# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Namespace (JavaScript fixtures)', type: :controller do
  include ApiHelpers
  include JavaScriptFixturesHelpers

  runners_token = 'runnerstoken:intabulasreferre'

  let(:namespace) { create(:namespace, name: 'frontend-fixtures' ) }

  let(:project_dummy) do
    create(
      :project,
      name: 'dummy project',
      path: 'dummy-project',
      namespace: namespace,
      runners_token: runners_token
    )
  end

  let(:project_boilerplate) do
    create(
      :project,
      name: 'Html5 Boilerplate',
      path: 'html5-boilerplate',
      namespace: namespace,
      runners_token: runners_token
    )
  end

  let(:project_twitter) do
    create(
      :project,
      name: 'Twitter',
      path: 'twitter',
      namespace: namespace,
      runners_token: runners_token
    )
  end

  let(:user) { project_dummy.owner }

  describe 'Storage' do
    describe GraphQL::Query, type: :request do
      include GraphqlHelpers
      context 'for project storage statistics query' do
        before do
          project_twitter.update!(
            repository_size_limit: 100_000
          )
          project_twitter.statistics.update!(
            repository_size: 209_710,
            lfs_objects_size: 209_720,
            build_artifacts_size: 1_272_375,
            pipeline_artifacts_size: 0,
            wiki_size: 0,
            packages_size: 0
          )

          project_dummy.update!(
            repository_size_limit: 100_000
          )
          project_dummy.statistics.update!(
            commit_count: 1,
            repository_size: 41_943,
            lfs_objects_size: 0,
            build_artifacts_size: 0,
            pipeline_artifacts_size: 0,
            wiki_size: 0,
            packages_size: 0
          )

          project_boilerplate.update!(
            repository_size_limit: 100_000
          )
          project_boilerplate.statistics.update!(
            repository_size: 0,
            lfs_objects_size: 0,
            build_artifacts_size: 1_272_375,
            pipeline_artifacts_size: 0,
            wiki_size: 0,
            packages_size: 0
          )
        end

        base_input_path = 'usage_quotas/storage/queries/'
        base_output_path = 'graphql/usage_quotas/storage/'
        query_name = 'namespace_storage.query.graphql'

        it "#{base_output_path}#{query_name}.json" do
          query = get_graphql_query_as_string("#{base_input_path}#{query_name}", ee: true)

          post_graphql(
            query,
            current_user: user,
            variables: {
              fullPath: namespace.full_path,
              first: 10,
              sortKey: 'STORAGE_SIZE_DESC'
            }
          )

          expect_graphql_errors_to_be_empty
        end
      end
    end
  end
end
