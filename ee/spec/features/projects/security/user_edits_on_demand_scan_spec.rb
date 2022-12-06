# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User edits On-demand Scan', feature_category: :dynamic_application_security_testing do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:dast_profile) { create(:dast_profile, project: project) }

  let(:on_demand_scans_path) { project_on_demand_scans_path(project) }
  let(:edit_on_demand_scan_path) { edit_project_on_demand_scan_path(project, dast_profile) }

  before_all do
    project.add_developer(user)
  end

  before do
    sign_in(user)
    stub_licensed_features(security_on_demand_scans: true)
    visit(edit_on_demand_scan_path)
  end

  it 'shows edit scan page', :aggregate_failures, :js do
    expect(page).to have_content 'Edit on-demand DAST scan'

    page.within '.breadcrumbs' do
      expect(page).to have_link('On-demand Scans', href: project_on_demand_scans_path(project, anchor: 'saved'))
      expect(page).to have_link('Edit on-demand DAST scan', href: edit_on_demand_scan_path)
    end
  end
end
