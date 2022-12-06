# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Delete Epic', :js, feature_category: :portfolio_management do
  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:epic) { create(:epic, group: group) }
  let!(:epic2) { create(:epic, group: group) }

  before do
    stub_licensed_features(epics: true)

    sign_in(user)
  end

  context 'when user who is not a group member displays the epic' do
    it 'does not show the Delete button' do
      visit group_epic_path(group, epic)

      expect(page).not_to have_css('[data-testid="desktop-dropdown"]')
    end
  end

  context 'when user with owner access displays the epic' do
    before do
      group.add_owner(user)
      visit group_epic_path(group, epic)
      wait_for_requests
      find('[data-testid="desktop-dropdown"]').click
    end

    it 'deletes the issue and redirect to epic list' do
      click_on 'Delete epic'
      wait_for_requests

      find('.js-modal-action-primary').click
      wait_for_requests

      expect(find('.issuable-list')).not_to have_content(epic.title)
      expect(find('.issuable-list')).to have_content(epic2.title)
    end
  end
end
