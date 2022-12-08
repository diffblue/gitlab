# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User creates On-demand Scan', feature_category: :dynamic_application_security_testing do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project) }
  let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile, project: project) }

  let(:on_demand_scans_path) { project_on_demand_scans_path(project) }
  let(:new_on_demand_scan_path) { new_project_on_demand_scan_path(project) }

  before_all do
    project.add_developer(user)
  end

  before do
    sign_in(user)
  end

  context 'when feature is available' do
    before do
      stub_licensed_features(security_on_demand_scans: true)
      visit(new_on_demand_scan_path)
    end

    it 'shows new scan page', :aggregate_failures, :js do
      expect(page).to have_content 'New on-demand scan'
      expect(page).to have_content 'Scan configuration'
      expect(page).to have_content 'DAST configuration'
      expect(page).to have_button 'Save and run scan'
      expect(page).to have_button 'Save scan'

      page.within '.breadcrumbs' do
        expect(page).to have_link('On-demand Scans', href: project_on_demand_scans_path(project, anchor: 'saved'))
        expect(page).to have_link('New on-demand DAST scan', href: new_on_demand_scan_path)
      end
    end

    it 'on save and run', :js do
      fill_in_form

      click_button 'Save and run scan'
      wait_for_requests

      expect(page).not_to have_current_path(on_demand_scans_path, ignore_query: true)
    end

    it 'on save', :js do
      fill_in_form

      click_button 'Save scan'
      wait_for_requests

      expect(page).to have_current_path(on_demand_scans_path, ignore_query: true)
    end

    it 'on cancel', :js do
      click_button 'Cancel'
      expect(page).to have_current_path(on_demand_scans_path, ignore_query: true)
    end
  end

  context 'when feature is not available' do
    before do
      visit(new_on_demand_scan_path)
    end

    it 'renders a 404' do
      expect(page).to have_gitlab_http_status(:not_found)
    end
  end

  def fill_in_form
    fill_in 'name', with: "My scan"
    fill_in 'description', with: "This is the description"
  end
end
