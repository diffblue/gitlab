# frozen_string_literal: true

module Projects::Security::DastProfilesHelper
  def dast_profiles_list_data(project)
    {
      'new_dast_site_profile_path' => new_project_security_configuration_dast_scans_dast_site_profile_path(project),
      'new_dast_scanner_profile_path' => new_project_security_configuration_dast_scans_dast_scanner_profile_path(project),
      'project_full_path' => project.path_with_namespace,
      'timezones' => timezone_data(format: :abbr).to_json
    }
  end
end
