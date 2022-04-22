# frozen_string_literal: true

module Projects::Security::DastConfigurationHelper
  def dast_configuration_data(project)
    {
      security_configuration_path: project_security_configuration_path(project),
      full_path: project.full_path,
      gitlab_ci_yaml_edit_path: Rails.application.routes.url_helpers.project_ci_pipeline_editor_path(project),
      scanner_profiles_library_path: project_security_configuration_profile_library_path(project, anchor: 'scanner-profiles'),
      site_profiles_library_path: project_security_configuration_profile_library_path(project, anchor: 'site-profiles'),
      new_scanner_profile_path: new_project_security_configuration_profile_library_dast_scanner_profile_path(project),
      new_site_profile_path: new_project_security_configuration_profile_library_dast_site_profile_path(project)
    }
  end
end
