# frozen_string_literal: true

module Projects::Security::DastProfilesHelper
  def dast_profiles_list_data(project)
    {
      'new_dast_site_profile_path' => new_project_security_configuration_profile_library_dast_site_profile_path(project),
      'new_dast_scanner_profile_path' => new_project_security_configuration_profile_library_dast_scanner_profile_path(project),
      'project_full_path' => project.path_with_namespace,
      'timezones' => timezone_data(format: :abbr).to_json
    }
  end

  def dast_scanner_profile_form_data(project)
    dast_profile_forms_common_data(project).merge({
      profiles_library_path: project_security_configuration_profile_library_path(project, anchor: 'scanner-profiles')
    })
  end

  def edit_dast_scanner_profile_form_data(project, scanner_profile)
    dast_scanner_profile_form_data(project).merge({
      scanner_profile: {
        id: scanner_profile.to_global_id.to_s,
        profile_name: scanner_profile.name,
        spider_timeout: scanner_profile.spider_timeout,
        target_timeout: scanner_profile.target_timeout,
        scan_type: scanner_profile.scan_type.upcase,
        use_ajax_spider: scanner_profile.use_ajax_spider,
        show_debug_messages: scanner_profile.show_debug_messages,
        referenced_in_security_policies: scanner_profile.referenced_in_security_policies
      }.to_json
    })
  end

  def dast_site_profile_form_data(project)
    dast_profile_forms_common_data(project).merge({
      profiles_library_path: project_security_configuration_profile_library_path(project, anchor: 'site-profiles')
    })
  end

  def edit_dast_site_profile_form_data(project, site_profile)
    dast_site_profile_form_data(project).merge({
      site_profile: site_profile.to_json
    })
  end

  private

  def dast_profile_forms_common_data(project)
    {
      project_full_path: project.path_with_namespace,
      on_demand_scan_form_path: params&.dig(:from_on_demand_scan_id) ? edit_project_on_demand_scan_path(project, id: params[:from_on_demand_scan_id]) : new_project_on_demand_scan_path(project),
      dast_configuration_path: project_security_configuration_dast_path(project)
    }
  end
end
