# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue actions', :js, feature_category: :team_planning do
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }
  let(:issue) { create(:issue, project: project) }
  let(:user) { create(:user) }

  before do
    stub_licensed_features(epics: true)
    sign_in(user)
  end

  describe 'promote issue to epic action' do
    context 'when user is unauthorized' do
      before do
        group.add_guest(user)
        visit project_issue_path(project, issue)
      end

      it 'does not show "Promote to epic" item in issue actions dropdown' do
        page.within '.detail-page-header' do
          # Click on ellipsis dropdown button
          click_button 'Issue actions'

          expect(page).not_to have_button('Promote to epic')
        end
      end
    end

    context 'when user is authorized' do
      before do
        group.add_owner(user)
        visit project_issue_path(project, issue)
      end

      it 'clicking "Promote to epic" creates and redirects user to epic' do
        page.within '.detail-page-header' do
          # Click on ellipsis dropdown button
          click_button 'Issue actions'

          click_button 'Promote to epic'
        end

        wait_for_requests

        expect(page).to have_current_path(group_epic_path(group, 1))
      end
    end
  end
end
