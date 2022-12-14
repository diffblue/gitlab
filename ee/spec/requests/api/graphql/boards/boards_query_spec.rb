# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'get list of boards', feature_category: :team_planning do
  include GraphqlHelpers

  include_context 'group and project boards query context'

  let_it_be(:parent_group) { create(:group) }
  let_it_be(:label) { create(:group_label, group: parent_group) }

  before do
    stub_licensed_features(multiple_group_issue_boards: true, epics: true)
  end

  shared_examples 'a board epics query' do
    before do
      parent_group.add_developer(current_user)
    end

    def board_epic_query(board)
      epic_query = <<~EPIC
        epics(issueFilters: {labelName: "#{label.title}", not: {authorUsername: "#{current_user.username}"}}) {
          nodes {
            id
            title
            userPreferences {
              collapsed
            }
          }
        }
      EPIC

      graphql_query_for(
        board_parent_type,
        { 'fullPath' => board_parent.full_path },
        query_graphql_field(
          'board', { id: global_id_of(board) },
          epic_query
        )
      )
    end

    def board_milestone_query(board)
      graphql_query_for(
        board_parent_type,
        { 'fullPath' => board_parent.full_path },
        query_graphql_field(
          'board', { id: global_id_of(board) },
          'milestone { id }'
        )
      )
    end

    context 'when board is scoped to a wildcard milestone' do
      it 'returns milestone global ID in the correct format' do
        board = create(:board, resource_parent: board_parent, milestone_id: -3)

        post_graphql(board_milestone_query(board), current_user: current_user)

        expect(graphql_data.dig(board_parent_type, "board", "milestone", "id")).to eq("gid://gitlab/Milestone/-3")
      end
    end

    it 'returns open epics referenced by issues in the board' do
      board = create(:board, resource_parent: board_parent)
      issue_project = board_parent.is_a?(Project) ? board_parent : create(:project, group: board_parent)
      # matches filters:
      issue1 = create(:issue, project: issue_project, labels: [label])
      # matches filters, but is assigned to the same epic as issue1:
      issue2 = create(:issue, project: issue_project, labels: [label])
      # doesn't match labelName filter:
      issue3 = create(:issue, project: issue_project)
      # matches filters, but its epic is closed:
      issue4 = create(:issue, project: issue_project, labels: [label])
      # doesn't match negated authorUsername filter:
      issue5 = create(:issue, project: issue_project, labels: [label], author: current_user)

      epic1 = create(:epic, group: parent_group)
      epic2 = create(:epic, group: parent_group)
      epic3 = create(:epic, :closed, group: parent_group)

      create(:epic_issue, issue: issue1, epic: epic1)
      create(:epic_issue, issue: issue2, epic: epic1)
      create(:epic_issue, issue: issue3, epic: epic2)
      create(:epic_issue, issue: issue4, epic: epic3)
      create(:epic_issue, issue: issue5, epic: epic2)

      create(:epic_user_preference, board: board, epic: epic1, user: current_user, collapsed: true)

      post_graphql(board_epic_query(board), current_user: current_user)

      aggregate_failures 'board epics response' do
        epics = board_data['epics']['nodes']

        expect(epics.size).to eq(1)
        expect(epics.first['title']).to eq(epic1.title)
        expect(epics.first['userPreferences']['collapsed']).to eq(true)
      end
    end
  end

  describe 'for a project' do
    let_it_be(:board_parent) { create(:project, group: parent_group) }

    it_behaves_like 'a board epics query'
  end

  describe 'for a group' do
    let_it_be(:board_parent) { create(:group, :private, parent: parent_group) }

    it_behaves_like 'group and project boards query'
    it_behaves_like 'a board epics query'
  end
end
