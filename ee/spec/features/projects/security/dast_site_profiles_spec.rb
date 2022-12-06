# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User creates Site profile', feature_category: :dynamic_application_security_testing do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  let(:profile_form_path) { new_project_security_configuration_profile_library_dast_site_profile_path(project) }
  let(:profile_library_path) { project_security_configuration_profile_library_path(project) }

  before_all do
    project.add_developer(user)
  end

  before do
    sign_in(user)
  end

  context 'when feature is available' do
    before do
      stub_licensed_features(security_on_demand_scans: true)
      visit(profile_form_path)
    end

    it 'shows the form' do
      expect(page).to have_gitlab_http_status(:ok)
      expect(page).to have_content("New site profile")
    end

    it 'on submit', :js do
      fill_in_profile_form
      expect(page).to have_current_path(profile_library_path, ignore_query: true)
    end

    it 'on cancel', :js do
      click_button 'Cancel'
      expect(page).to have_current_path(profile_library_path, ignore_query: true)
    end
  end

  context 'when feature is not available' do
    before do
      visit(profile_form_path)
    end

    it 'renders a 404' do
      expect(page).to have_gitlab_http_status(:not_found)
    end
  end

  def fill_in_profile_form
    fill_in 'profileName', with: "hello"
    fill_in 'targetUrl', with: "https://example.com"
    click_button 'Save profile'
    wait_for_requests
  end
end
