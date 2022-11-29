# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Boards', :js, feature_category: :team_planning do
  let(:group) { create(:group) }
  let!(:board_ux) { create(:board, group: group, name: 'UX') }
  let!(:board_dev) { create(:board, group: group, name: 'Dev') }
  let(:user) { create(:group_member, user: create(:user), group: group).user }

  before do
    stub_licensed_features(multiple_group_issue_boards: true)
    sign_in(user)
    visit group_boards_path(group)
    wait_for_requests
  end

  it 'deletes a group issue board' do
    click_boards_dropdown

    wait_for_requests

    click_button s_('IssueBoards|Delete board')
    find(:css, '.board-config-modal .js-modal-action-primary').click

    click_boards_dropdown

    expect(page).not_to have_content(board_dev.name)
    expect(page).to have_content(board_ux.name)
  end

  def click_boards_dropdown
    find('[data-testid="boards-dropdown"]').click
  end
end
