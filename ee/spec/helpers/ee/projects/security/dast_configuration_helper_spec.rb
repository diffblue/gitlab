# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::DastConfigurationHelper do
  let_it_be(:project) { create(:project) }

  let(:security_configuration_path) { project_security_configuration_path(project) }
  let(:full_path) { project.full_path }
  let(:gitlab_ci_yaml_edit_path) { Rails.application.routes.url_helpers.project_ci_pipeline_editor_path(project) }
  let(:scanner_profiles_library_path) { project_security_configuration_profile_library_path(project, anchor: 'scanner-profiles')}
  let(:site_profiles_library_path) { project_security_configuration_profile_library_path(project, anchor: 'site-profiles')}
  let(:new_scanner_profile_path) { new_project_security_configuration_profile_library_dast_scanner_profile_path(project) }
  let(:new_site_profile_path) { new_project_security_configuration_profile_library_dast_site_profile_path(project) }

  describe '#dast_configuration_data' do
    subject { helper.dast_configuration_data(project) }

    it {
      is_expected.to eq({
        security_configuration_path: security_configuration_path,
        full_path: full_path,
        gitlab_ci_yaml_edit_path: gitlab_ci_yaml_edit_path,
        scanner_profiles_library_path: scanner_profiles_library_path,
        site_profiles_library_path: site_profiles_library_path,
        new_scanner_profile_path: new_scanner_profile_path,
        new_site_profile_path: new_site_profile_path
      })
    }
  end
end
