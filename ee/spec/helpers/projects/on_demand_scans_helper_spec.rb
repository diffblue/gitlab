# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::OnDemandScansHelper do
  let_it_be(:project) { create(:project) }
  let_it_be(:path_with_namespace) { "foo/bar" }
  let_it_be(:graphql_etag_project_on_demand_scan_counts_path) { "/api/graphql:#{path_with_namespace}/on_demand_scans/counts" }
  let_it_be(:timezones) { [{ identifier: "Europe/Paris" }] }

  before do
    allow(project).to receive(:path_with_namespace).and_return(path_with_namespace)
  end

  describe '#on_demand_scans_data' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:dast_profile) { create(:dast_profile, project: project) }
    let_it_be(:dast_profile_with_schedule) { create(:dast_profile, project: project) }
    let_it_be(:dast_profile_schedule) { create(:dast_profile_schedule, project: project, dast_profile: dast_profile_with_schedule) }

    before do
      allow(helper).to receive(:timezone_data).with(format: :abbr).and_return(timezones)
      create_list(:ci_pipeline, 8, :success, project: project, ref: 'master', source: :ondemand_dast_scan)
      create_list(:ci_pipeline, 4, :running, project: project, ref: 'master', source: :ondemand_dast_scan)
      allow(helper).to receive(:graphql_etag_project_on_demand_scan_counts_path).and_return(graphql_etag_project_on_demand_scan_counts_path)
      project.add_developer(current_user)
      stub_licensed_features(security_on_demand_scans: true)
    end

    it 'returns proper data' do
      expect(helper.on_demand_scans_data(current_user, project)).to match(
        'project-path' => "foo/bar",
        'new-dast-scan-path' => "/#{project.full_path}/-/on_demand_scans/new",
        'empty-state-svg-path' => match_asset_path('/assets/illustrations/empty-state/ondemand-scan-empty.svg'),
        'can-edit-on-demand-scans' => "true",
        'project-on-demand-scan-counts-etag' => graphql_etag_project_on_demand_scan_counts_path,
        'on-demand-scan-counts' => {
          all: 12,
          running: 4,
          finished: 8,
          scheduled: 1,
          saved: 2
        }.to_json,
        'timezones' => timezones.to_json
      )
    end
  end

  describe '#on_demand_scans_form_data' do
    let_it_be(:user) { create(:user) }

    before do
      allow(helper).to receive(:timezone_data).with(format: :full).and_return(timezones)
      allow(project).to receive(:default_branch).and_return("default-branch")
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'returns proper data' do
      expect(helper.on_demand_scans_form_data(project)).to match(
        'can_edit_runner_tags' => "false",
        'default-branch' => "default-branch",
        'project-path' => "foo/bar",
        'on-demand-scans-path' => "/#{project.full_path}/-/on_demand_scans#saved",
        'scanner-profiles-library-path' => "/#{project.full_path}/-/security/configuration/profile_library#scanner-profiles",
        'site-profiles-library-path' => "/#{project.full_path}/-/security/configuration/profile_library#site-profiles",
        'new-scanner-profile-path' => "/#{project.full_path}/-/security/configuration/profile_library/dast_scanner_profiles/new",
        'new-site-profile-path' => "/#{project.full_path}/-/security/configuration/profile_library/dast_site_profiles/new",
        'timezones' => timezones.to_json
      )
    end
  end
end
