# frozen_string_literal: true

module Projects::OnDemandScansHelper
  def on_demand_scans_data(project)
    {
      'help-page-path' => help_page_path('user/application_security/dast/index', anchor: 'on-demand-scans'),
      'empty-state-svg-path' => image_path('illustrations/empty-state/ondemand-scan-empty.svg'),
      'default-branch' => project.default_branch,
      'project-path' => project.path_with_namespace,
      'profiles-library-path' => project_security_configuration_dast_scans_path(project),
      'scanner-profiles-library-path' => project_security_configuration_dast_scans_path(project, anchor: 'scanner-profiles'),
      'site-profiles-library-path' => project_security_configuration_dast_scans_path(project, anchor: 'site-profiles'),
      'new-scanner-profile-path' => new_project_security_configuration_dast_scans_dast_scanner_profile_path(project),
      'new-site-profile-path' => new_project_security_configuration_dast_scans_dast_site_profile_path(project),
      'timezones' => timezone_data(format: :full).to_json
    }
  end
end
