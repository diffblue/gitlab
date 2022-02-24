# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Contribution Analytics', :js do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:empty_project) { create(:project, namespace: group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  describe 'visit Contribution Analytics page for group' do
    it 'displays Contribution Analytics' do
      visit group_path(group)

      within('.nav-sidebar') do
        find('a', text: 'Analytics').click

        within('.sidebar-sub-level-items') do
          find('a', text: 'Contribution').click
        end
      end

      expect(page).to have_content "Contribution analytics for issues, merge requests and push"
    end

    it 'displays text indicating no pushes, merge requests and issues' do
      visit group_path(group)

      within('.nav-sidebar') do
        find('a', text: 'Analytics').click

        within('.sidebar-sub-level-items') do
          find('a', text: 'Contribution').click
        end
      end
      expect(page).to have_content "No pushes for the selected time period."
      expect(page).to have_content "No merge requests for the selected time period."
      expect(page).to have_content "No issues for the selected time period."
    end
  end
end
