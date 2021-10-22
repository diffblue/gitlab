# frozen_string_literal: true

module Projects::OnDemandScansHelper
  include API::Helpers::GraphqlHelpers

  def on_demand_scans_data(project)
    query = %(
      {
        project(fullPath: "#{project.full_path}") {
          pipelines(source: "dast") {
            count
          }
        }
      }
    )
    pipelines_count = run_graphql!(
      query: query,
      context: { current_user: current_user },
      transform: -> (result) { result.dig('data', 'project', 'pipelines', 'count') }
    )

    common_data(project).merge({
      'pipelines-count' => pipelines_count,
      'new-dast-scan-path' => new_project_on_demand_scan_path(project),
      'empty-state-svg-path' => image_path('illustrations/empty-state/ondemand-scan-empty.svg')
    })
  end

  def on_demand_scans_form_data(project)
    common_data(project).merge({
      'default-branch' => project.default_branch,
      'profiles-library-path' => project_security_configuration_dast_scans_path(project),
      'scanner-profiles-library-path' => project_security_configuration_dast_scans_path(project, anchor: 'scanner-profiles'),
      'site-profiles-library-path' => project_security_configuration_dast_scans_path(project, anchor: 'site-profiles'),
      'new-scanner-profile-path' => new_project_security_configuration_dast_scans_dast_scanner_profile_path(project),
      'new-site-profile-path' => new_project_security_configuration_dast_scans_dast_site_profile_path(project),
      'timezones' => timezone_data(format: :full).to_json
    })
  end

  private

  def common_data(project)
    {
      'project-path' => project.path_with_namespace
    }
  end
end
