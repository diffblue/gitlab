# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Querying an Epic board list', feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:board) { create(:epic_board, group: group) }
  let_it_be(:label) { create(:group_label, group: group, name: 'Development') }
  let_it_be(:list) { create(:epic_list, epic_board: board, label: label) }
  let_it_be(:epic1) { create(:epic, group: group, labels: [label], title: 'Epic1') }
  let_it_be(:epic2) { create(:epic, group: group, labels: [label], title: 'Epic2') }
  let_it_be(:epic3) { create(:epic, group: group, labels: [label], title: 'Epic3') }

  let(:filters) { {} }
  let(:query) do
    graphql_query_for(
      :epic_board_list,
      { id: list.to_global_id.to_s, epicFilters: filters }, %w[id]
    )
  end

  subject { graphql_data['epicBoardList'] }

  before do
    stub_licensed_features(epics: true)
    post_graphql(query, current_user: current_user)
  end

  context 'when the user has access to the epic list' do
    before_all do
      group.add_guest(current_user)
    end

    it_behaves_like 'a working graphql query'

    it { is_expected.to include({ 'id' => list.to_global_id.to_s }) }
  end

  context 'when the user does not have access to the list' do
    it { is_expected.to be_nil }
  end

  context 'when ID argument is missing' do
    let(:query) do
      graphql_query_for('epicBoardList', {}, 'title')
    end

    it 'raises an exception' do
      expect(graphql_errors).to include(a_hash_including('message' =>
        "Field 'epicBoardList' is missing required arguments: id"))
    end
  end

  context 'when list ID is not found' do
    let(:query) do
      graphql_query_for('boardList', { id: "gid://gitlab/List/#{non_existing_record_id}" }, 'title')
    end

    it { is_expected.to be_nil }
  end

  it 'does not have an N+1 when querying title' do
    a, b = create_list(:epic_list, 2, epic_board: board)
    ctx = { current_user: current_user }
    group.add_guest(current_user)

    baseline = graphql_query_for(:epic_board_list, { id: global_id_of(a) }, 'title')
    query = <<~GQL
      query {
        a: #{query_graphql_field(:epic_board_list, { id: global_id_of(a) }, 'title')}
        b: #{query_graphql_field(:epic_board_list, { id: global_id_of(b) }, 'title')}
      }
    GQL

    control = ActiveRecord::QueryRecorder.new do
      run_with_clean_state(baseline, context: ctx)
    end

    expect { run_with_clean_state(query, context: ctx) }.not_to exceed_query_limit(control)
  end
end
