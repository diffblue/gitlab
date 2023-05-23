# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'On-call Schedules', :js, feature_category: :on_call_schedule_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project) }

  before do
    stub_licensed_features(oncall_schedules: true)

    project.add_maintainer(user)
    sign_in(user)

    visit project_incident_management_oncall_schedules_path(project)
    wait_for_all_requests
  end

  context 'displaying the empty state by default' do
    it { expect(page).to have_button 'Add schedule' }
  end

  context 'creating a schedule' do
    it 'adds a schedule given valid options' do
      click_button 'Add schedule'
      fill_in 'schedule-name', with: 'Test schedule'
      fill_in 'schedule-description', with: 'Test schedule description'

      click_button 'Select timezone'
      page.find("li", text: "[UTC-12] International Date Line West").click
      within_element(id: 'addScheduleModal') do
        click_button 'Add schedule'
      end

      wait_for_all_requests
      expect(page).to have_css '.gl-alert-tip'
      expect(page).to have_css '.gl-card'
      expect(page).to have_text 'Test schedule'
      expect(page).to have_text 'Test schedule description | (UTC -12:00) Etc/GMT+12'
    end
  end
end
