# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting project information', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:epic) { create(:epic, group: group) }
  let_it_be(:epic_todo) { create(:todo, user: current_user, target: epic) }

  let(:fields) do
    <<~QUERY
    nodes {
      #{all_graphql_fields_for('todos'.classify)}
    }
    QUERY
  end

  let(:query) do
    graphql_query_for('currentUser', {}, query_graphql_field('todos', {}, fields))
  end

  subject { graphql_data.dig('currentUser', 'todos', 'nodes') }

  before_all do
    group.add_developer(current_user)
  end

  before do
    stub_licensed_features(epics: true)

    post_graphql(query, current_user: current_user)
  end

  it_behaves_like 'a working graphql query'

  it 'returns Todos for all target types' do
    is_expected.to include(
      a_hash_including('targetType' => 'EPIC')
    )
  end
end
