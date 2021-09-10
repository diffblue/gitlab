# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::DastProfilesHelper do
  describe '#dast_profiles_list_data' do
    let(:project) { create(:project) }

    it 'returns proper data' do
      expect(helper.dast_profiles_list_data(project)).to eq(
        {
          'new_dast_saved_scan_path' => new_project_on_demand_scan_path(project),
          'new_dast_site_profile_path' => new_project_security_configuration_dast_scans_dast_site_profile_path(project),
          'new_dast_scanner_profile_path' => new_project_security_configuration_dast_scans_dast_scanner_profile_path(project),
          'project_full_path' => project.path_with_namespace,
          'timezones' => helper.timezone_data(format: :full).to_json
        }
      )
    end
  end
end
