# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.workspaces(ids: [RemoteDevelopmentWorkspaceID!])', feature_category: :remote_development do
  include GraphqlHelpers

  let_it_be(:workspace) { create(:workspace) }
  let_it_be(:current_user) { workspace.user }
  let(:ids) { [workspace.to_global_id.to_s] }
  let(:fields) do
    <<~QUERY
      nodes {
        #{all_graphql_fields_for('workspaces'.classify, max_depth: 2)}
      }
    QUERY
  end

  let(:query) do
    graphql_query_for('workspaces', { ids: ids }, fields)
  end

  subject { graphql_data.dig('workspaces', 'nodes') }

  context 'when licensed and remote_development_feature_flag feature flag is enabled' do
    before do
      stub_licensed_features(remote_development: true)

      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query'

    # noinspection RubyResolve
    it { is_expected.to match_array(a_hash_including('name' => workspace.name)) }
    # noinspection RubyResolve

    context 'when the user requests a workspace that they are not authorized for' do
      let_it_be(:other_workspace) { create(:workspace) }
      # noinspection RubyResolve
      let(:ids) do
        [
          workspace.to_global_id.to_s,
          other_workspace.to_global_id.to_s
        ]
      end

      it 'does not contain fields for the other workspace' do
        # noinspection RubyResolve
        expect(subject).to match_array(a_hash_including('name' => workspace.name))
      end
    end
  end

  context 'when remote_development feature is unlicensed' do
    before do
      stub_licensed_features(remote_development: false)
      post_graphql(query, current_user: current_user)
    end

    it 'returns an error' do
      expect(subject).to be_nil
      expect_graphql_errors_to_include(/'remote_development' licensed feature is not available/)
    end
  end

  context 'when remote_development_feature_flag feature flag is disabled' do
    before do
      stub_licensed_features(remote_development: true)
      stub_feature_flags(remote_development_feature_flag: false)
      post_graphql(query, current_user: current_user)
    end

    it 'returns an error' do
      expect(subject).to be_nil
      expect_graphql_errors_to_include(/'remote_development_feature_flag' feature flag is disabled/)
    end
  end
end
