# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue boards sidebar labels using epic swimlanes', :js, feature_category: :team_planning do
  include BoardHelpers

  include_context 'labels from nested groups and projects'

  before do
    stub_licensed_features(epics: true, swimlanes: true)
    stub_feature_flags(apollo_boards: false)
  end

  let(:card) { find("[data-testid='board-lane-unassigned-issues']").first("[data-testid='board_card']") }

  context 'group boards' do
    context 'in the top-level group board' do
      let_it_be(:group_board) { create(:board, group: group) }
      let_it_be(:board_list) { create(:backlog_list, board: group_board) }

      before do
        load_board group_board_path(group, group_board)
        load_epic_swimlanes
        load_unassigned_issues
      end

      context 'selecting an issue from a direct descendant project' do
        let_it_be(:project_issue) { create(:issue, project: project) }

        include_examples 'an issue from a direct descendant project is selected'
      end

      context "selecting an issue from a subgroup's project" do
        let_it_be(:subproject_issue) { create(:issue, project: subproject) }

        include_examples "an issue from a subgroup's project is selected"
      end
    end
  end
end
