# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'epics swimlanes sidebar', :js, feature_category: :team_planning,
  quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/390752' do
  include BoardHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project, reload: true) { create(:project, :public, group: group) }

  let_it_be(:board) { create(:board, project: project) }
  let_it_be(:label) { create(:label, project: project, name: 'Label 1') }
  let_it_be(:list) { create(:list, board: board, label: label, position: 0) }

  let_it_be(:issue, reload: true) { create(:issue, project: project) }

  before do
    stub_feature_flags(apollo_boards: false)
    stub_licensed_features(epics: true, swimlanes: true)

    project.add_maintainer(user)
    group.add_maintainer(user)

    sign_in(user)
  end

  context "in project boards", :js do
    before do
      visit project_boards_path(project)

      wait_for_requests

      load_epic_swimlanes

      load_unassigned_issues
    end

    it_behaves_like 'issue boards sidebar'
    it_behaves_like 'issue boards sidebar EE'
  end

  context 'in group boards', :js do
    before do
      visit group_boards_path(group)

      wait_for_requests

      load_epic_swimlanes

      load_unassigned_issues
    end

    it_behaves_like 'issue boards sidebar'
    it_behaves_like 'issue boards sidebar EE'
  end

  def first_card
    find("[data-testid='board-lane-unassigned-issues']").first("[data-testid='board_card']")
  end

  def first_card_with_epic
    find("[data-testid='board-epic-lane-issues']").first("[data-testid='board_card']")
  end

  def refresh_and_click_first_card
    page.refresh

    wait_for_requests

    load_unassigned_issues

    first_card.click
  end
end
