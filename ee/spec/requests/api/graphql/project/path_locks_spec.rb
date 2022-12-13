# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).pathLocks', feature_category: :source_code_management do
  using RSpec::Parameterized::TableSyntax
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: user.namespace) }
  let_it_be(:path_lock) { create(:path_lock, project: project, path: 'README.md') }

  subject(:path_locks_response) do
    post_graphql(
      graphql_query_for(
        :project, { full_path: project.full_path }, "pathLocks { nodes { #{all_graphql_fields_for('PathLock')} } }"
      ),
      current_user: user
    )

    graphql_data_at(:project, :pathLocks, :nodes)
  end

  context 'unlicensed feature' do
    before do
      stub_licensed_features(file_locks: false)
    end

    it { is_expected.to be_empty }
  end

  context 'licensed feature' do
    before do
      stub_licensed_features(file_locks: true)
    end

    it 'returns path locks' do
      is_expected.to match_array(
        a_hash_including('id' => path_lock.to_global_id.to_s, 'path' => 'README.md')
      )
    end
  end
end
