# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::DastProfilesHelper do
  describe '#dast_profiles_list_data' do
    let_it_be(:project) { create(:project) }
    let_it_be(:timezones) { [{ identifier: "Europe/Paris" }] }

    before do
      allow(project).to receive(:path_with_namespace).and_return("foo/bar")
      allow(helper).to receive(:timezone_data).with(format: :abbr).and_return(timezones)
    end

    it 'returns proper data' do
      expect(helper.dast_profiles_list_data(project)).to eq(
        {
          'new_dast_site_profile_path' => "/#{project.full_path}/-/security/configuration/dast_scans/dast_site_profiles/new",
          'new_dast_scanner_profile_path' => "/#{project.full_path}/-/security/configuration/dast_scans/dast_scanner_profiles/new",
          'project_full_path' => "foo/bar",
          'timezones' => timezones.to_json
        }
      )
    end
  end
end
