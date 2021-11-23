# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::OnDemandScansHelper do
  let_it_be(:project) { create(:project) }
  let_it_be(:path_with_namespace) { "foo/bar" }
  let_it_be(:graphql_etag_project_on_demand_scan_counts_path) {"/api/graphql:#{path_with_namespace}/on_demand_scans/counts" }

  before do
    allow(project).to receive(:path_with_namespace).and_return(path_with_namespace)
  end

  describe '#on_demand_scans_data' do
    before do
      create_list(:ci_pipeline, 8, :success, project: project, ref: 'master', source: :ondemand_dast_scan)
      create_list(:ci_pipeline, 4, :running, project: project, ref: 'master', source: :ondemand_dast_scan)
      allow(helper).to receive(:graphql_etag_project_on_demand_scan_counts_path).and_return(graphql_etag_project_on_demand_scan_counts_path)
    end

    it 'returns proper data' do
      expect(helper.on_demand_scans_data(project)).to match(
        'project-path' => "foo/bar",
        'new-dast-scan-path' => "/#{project.full_path}/-/on_demand_scans/new",
        'empty-state-svg-path' => match_asset_path('/assets/illustrations/empty-state/ondemand-scan-empty.svg'),
        'project-on-demand-scan-counts-etag' => graphql_etag_project_on_demand_scan_counts_path,
        'on-demand-scan-counts' => {
          all: 12,
          running: 4,
          finished: 8
        }.to_json
      )
    end
  end

  describe '#on_demand_scans_form_data' do
    let_it_be(:timezones) { [{ identifier: "Europe/Paris" }] }

    before do
      allow(project).to receive(:default_branch).and_return("default-branch")
      allow(helper).to receive(:timezone_data).with(format: :full).and_return(timezones)
    end

    it 'returns proper data' do
      expect(helper.on_demand_scans_form_data(project)).to match(
        'default-branch' => "default-branch",
        'project-path' => "foo/bar",
        'profiles-library-path' => "/#{project.full_path}/-/security/configuration/dast_scans",
        'scanner-profiles-library-path' => "/#{project.full_path}/-/security/configuration/dast_scans#scanner-profiles",
        'site-profiles-library-path' => "/#{project.full_path}/-/security/configuration/dast_scans#site-profiles",
        'new-scanner-profile-path' => "/#{project.full_path}/-/security/configuration/dast_scans/dast_scanner_profiles/new",
        'new-site-profile-path' => "/#{project.full_path}/-/security/configuration/dast_scans/dast_site_profiles/new",
        'timezones' => timezones.to_json
      )
    end
  end
end
