# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'get board lists', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user)       { create(:user) }
  let_it_be(:group)              { create(:group, :private) }
  let_it_be(:project)            { create(:project, creator_id: current_user.id, group: group) }
  let_it_be(:project_milestone)  { create(:milestone, project: project) }
  let_it_be(:project_milestone2) { create(:milestone, project: project) }
  let_it_be(:group_milestone)    { create(:milestone, group: group) }
  let_it_be(:group_milestone2)   { create(:milestone, group: group) }
  let_it_be(:assignee)           { create(:assignee) }
  let_it_be(:assignee2)          { create(:assignee) }
  let_it_be(:label)              { create(:group_label, group: group) }
  let_it_be(:label2)             { create(:group_label, group: group) }

  let(:params)            { '' }
  let(:board)             {}
  let(:board_parent_type) { board_parent.class.to_s.downcase }
  let(:board_data)        { graphql_data[board_parent_type]['boards']['edges'].first['node'] }
  let(:lists_data)        { board_data['lists']['edges'] }
  let(:start_cursor)      { board_data['lists']['pageInfo']['startCursor'] }
  let(:end_cursor)        { board_data['lists']['pageInfo']['endCursor'] }

  before do
    stub_licensed_features(board_assignee_lists: true, board_milestone_lists: true)
  end

  def query(list_params = params)
    graphql_query_for(
      board_parent_type,
      { 'fullPath' => board_parent.full_path },
      <<~BOARDS
      boards(first: 1) {
        edges {
          node {
            #{field_with_params('lists', list_params)} {
              pageInfo {
                startCursor
                endCursor
              }
              edges {
                node {
                  #{all_graphql_fields_for('board_lists'.classify)}
                }
              }
            }
          }
        }
      }
    BOARDS
    )
  end

  shared_examples 'group and project board lists query' do
    let!(:board) { create(:board, resource_parent: board_parent) }

    context 'when user can read the board' do
      before do
        board_parent.add_reporter(current_user)
      end

      describe 'sorting and pagination' do
        let(:data_path) { [board_parent_type, :boards, :nodes, 0, :lists] }

        def pagination_query(params)
          graphql_query_for(
            board_parent_type,
            { 'fullPath' => board_parent.full_path },
            <<~BOARDS
              boards(first: 1) {
                nodes {
                  #{query_nodes(:lists, :id, args: params, include_pagination_info: true)}
                }
              }
            BOARDS
          )
        end

        context 'when using default sorting' do
          let!(:milestone_list)  { create(:milestone_list, board: board, milestone: milestone, position: 10) }
          let!(:milestone_list2) { create(:milestone_list, board: board, milestone: milestone2, position: 2) }
          let!(:assignee_list)   { create(:user_list, board: board, user: assignee, position: 5) }
          let!(:assignee_list2)  { create(:user_list, board: board, user: assignee2, position: 1) }
          let(:closed_list)      { board.lists.find_by(list_type: :closed) }
          let(:lists)            { [closed_list, assignee_list2, assignee_list, milestone_list2, milestone_list] }

          context 'when ascending' do
            it_behaves_like 'sorted paginated query' do
              include_context 'no sort argument'

              let(:first_param) { 2 }
              let(:all_records) { lists.map { |list| global_id_of(list).to_s } }
            end
          end
        end
      end

      describe 'limit metric settings' do
        let(:limit_metric_params) { { limit_metric: 'issue_count', max_issue_count: 10, max_issue_weight: 4 } }
        let!(:list_with_limit_metrics) { create(:list, board: board, **limit_metric_params) }

        before do
          post_graphql(query, current_user: current_user)
        end

        it 'returns the expected limit metric settings' do
          lists = grab_list_data(response.body).map { |item| item['node'] }

          list = lists.find { |l| l['id'] == list_with_limit_metrics.to_global_id.to_s }

          expect(list['limitMetric']).to eq('issue_count')
          expect(list['maxIssueCount']).to eq(10)
          expect(list['maxIssueWeight']).to eq(4)
        end
      end

      describe 'total issue count and weight' do
        it 'returns total count and weight of issues matching issue filters' do
          label_list = create(:list, board: board, label: label, position: 10)
          create(:issue, project: project, labels: [label, label2], weight: 2)
          create(:issue, project: project, labels: [label], weight: 2)

          post_graphql(query(id: global_id_of(label_list), issueFilters: { labelName: label2.title }), current_user: current_user)

          aggregate_failures do
            list_node = lists_data[0]['node']

            expect(list_node['title']).to eq label_list.title
            expect(list_node['issuesCount']).to eq 1
            expect(list_node['totalWeight']).to eq 2
          end
        end
      end
    end
  end

  describe 'for a project' do
    let(:board_parent) { project }
    let(:milestone)    { project_milestone }
    let(:milestone2)   { project_milestone2 }

    it_behaves_like 'group and project board lists query'
  end

  describe 'for a group' do
    let(:board_parent) { group }
    let(:milestone)    { group_milestone }
    let(:milestone2)   { group_milestone2 }

    before do
      allow(board_parent).to receive(:multiple_issue_boards_available?).and_return(false)
    end

    it_behaves_like 'group and project board lists query'
  end

  def grab_list_data(response_body)
    keys = [:data, board_parent_type, :boards, :edges, 0, :node, :lists, :edges]
    graphql_dig_at(Gitlab::Json.parse(response_body), *keys)
  end
end
