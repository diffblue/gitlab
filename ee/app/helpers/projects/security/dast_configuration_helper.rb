# frozen_string_literal: true

module Projects::Security::DastConfigurationHelper
  def dast_configuration_data(project, current_user)
    config = {
      security_configuration_path: project_security_configuration_path(project),
      full_path: project.full_path,
      gitlab_ci_yaml_edit_path: Rails.application.routes.url_helpers.project_ci_pipeline_editor_path(project),
      scanner_profiles_library_path: project_security_configuration_profile_library_path(project, anchor: 'scanner-profiles'),
      site_profiles_library_path: project_security_configuration_profile_library_path(project, anchor: 'site-profiles'),
      new_scanner_profile_path: new_project_security_configuration_profile_library_dast_scanner_profile_path(project),
      new_site_profile_path: new_project_security_configuration_profile_library_dast_site_profile_path(project)
    }

    config.merge!(yml_config_data(project, current_user))

    config.merge!(pipeline_data(project, current_user))

    config
  end

  private

  def yml_config_data(project, current_user)
    service_response = AppSec::Dast::ScanConfigs::FetchService.new(
      project: project, current_user: current_user
    ).execute

    return {} unless service_response.success?

    service_response.payload
  end

  def pipeline_data(project, current_user)
    service_response = AppSec::Dast::Pipelines::FindLatestService.new(
      project: project, current_user: current_user
    ).execute

    return {} unless service_response.success?

    latest_pipeline = service_response.payload[:latest_pipeline]

    pipeline_data = {
      dast_enabled: !!latest_pipeline
    }

    if latest_pipeline
      pipeline_data.merge!(
        {
          pipeline_id: latest_pipeline.id,
          pipeline_created_at: latest_pipeline.created_at,
          pipeline_path: project_pipeline_path(project, latest_pipeline)
        }
      )
    end

    pipeline_data
  end
end
