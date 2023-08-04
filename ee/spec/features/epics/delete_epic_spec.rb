# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Delete Epic', :js, feature_category: :portfolio_management do
  include Spec::Support::Helpers::ModalHelpers

  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:epic) { create(:epic, group: group) }
  let!(:epic2) { create(:epic, group: group) }

  before do
    stub_licensed_features(epics: true)

    sign_in(user)
  end

  context 'when user who is not a group member displays the epic' do
    before do
      visit group_epic_path(group, epic)
      wait_for_requests
      click_button _('Epic actions')
    end

    it 'does not show the `Delete epic` button' do
      expect(page).not_to have_button _('Delete epic')
    end
  end

  context 'when user with owner access displays the epic' do
    before do
      group.add_owner(user)
      visit group_epic_path(group, epic)
      wait_for_requests
      click_button _('Epic actions')
    end

    it 'deletes the issue and redirect to epic list' do
      click_button _('Delete epic')
      within_modal do
        click_button _('Delete epic')
      end

      expect(find('.issuable-list')).not_to have_content(epic.title)
      expect(find('.issuable-list')).to have_content(epic2.title)
    end
  end
end
