# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.currentUser.workspaces', feature_category: :remote_development do
  include GraphqlHelpers

  let_it_be(:workspace) { create(:workspace) }
  let(:current_user) { workspace.user }
  let(:fields) do
    <<~QUERY
      nodes {
        #{all_graphql_fields_for('workspaces'.classify, max_depth: 2)}
      }
    QUERY
  end

  let(:query) do
    graphql_query_for('currentUser', {}, query_graphql_field('workspaces', {}, fields))
  end

  subject { graphql_data.dig('currentUser', 'workspaces', 'nodes') }

  it_behaves_like 'workspaces query in licensed environment and with feature flag on'
  it_behaves_like 'workspaces query in unlicensed environment and with feature flag off'
end
