# frozen_string_literal: true

# To be removed as :graphql_board_lists gets removed
# https://gitlab.com/gitlab-org/gitlab/-/issues/248908

require 'spec_helper'

RSpec.describe 'label issues', :js do
  include BoardHelpers

  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:project) { create(:project, :public, namespace: group) }
  let(:board) { create(:board, group: group) }
  let!(:development) { create(:label, project: project, name: 'Development') }
  let!(:issue) { create(:labeled_issue, project: project, labels: [development]) }
  let!(:list) { create(:list, board: board, label: development, position: 0) }

  before do
    stub_licensed_features(multiple_group_issue_boards: true)
    # stubbing until sidebar work is done: https://gitlab.com/gitlab-org/gitlab/-/issues/230711
    stub_feature_flags(graphql_board_lists: false)
    group.add_maintainer(user)

    sign_in(user)

    visit group_boards_path(group)
    wait_for_requests
  end

  it 'adds a new group label from sidebar' do
    card = find('.board:nth-child(2)').first('.board-card')
    click_card(card)

    page.within '.right-sidebar .labels' do
      click_link 'Edit'
      click_link 'Create group label'
      fill_in 'new_label_name', with: 'test label'
      first('.suggest-colors-dropdown a').click

      # We need to hover before clicking to trigger
      # dropdown repositioning so that the click isn't flaky
      create_button = find_button('Create')
      create_button.hover
      create_button.click
    end

    page.within '.labels' do
      expect(page).to have_link 'test label'
    end
  end
end
