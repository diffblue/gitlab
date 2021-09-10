# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::OnDemandScansHelper do
  describe '#on_demand_scans_data' do
    let_it_be(:project) { create(:project) }
    let_it_be(:default_branch) { 'default-branch' }
    let_it_be(:path_with_namespace) { 'foo/bar' }
    let_it_be(:timezones) { [{ identifier: "Europe/Paris" }] }

    before do
      allow(project).to receive(:default_branch).and_return(default_branch)
      allow(project).to receive(:path_with_namespace).and_return(path_with_namespace)
      allow(helper).to receive(:timezone_data).with(format: :full).and_return(timezones)
    end

    it 'returns proper data' do
      expect(helper.on_demand_scans_data(project)).to match(
        'help-page-path' => "/help/user/application_security/dast/index#on-demand-scans",
        'empty-state-svg-path' => match_asset_path('/assets/illustrations/empty-state/ondemand-scan-empty.svg'),
        'default-branch' => default_branch,
        'project-path' => path_with_namespace,
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
