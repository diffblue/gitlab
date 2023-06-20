# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.workspaces(include_actual_states: [GraphQL::Types::String])', feature_category: :remote_development do
  include GraphqlHelpers

  let_it_be(:workspace) { create(:workspace, actual_state: ::RemoteDevelopment::Workspaces::States::RUNNING) }
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
    graphql_query_for('workspaces',
      { include_actual_states: [::RemoteDevelopment::Workspaces::States::RUNNING] },
      fields
    )
  end

  subject { graphql_data.dig('workspaces', 'nodes') }

  it_behaves_like 'workspaces query in licensed environment and with feature flag on'
  it_behaves_like 'workspaces query in unlicensed environment and with feature flag off'
end
