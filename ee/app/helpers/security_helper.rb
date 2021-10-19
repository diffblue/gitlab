# frozen_string_literal: true

module SecurityHelper
  def instance_security_dashboard_data
    {
      dashboard_documentation: help_page_path('user/application_security/security_dashboard/index', anchor: 'instance-security-dashboard'),
      no_vulnerabilities_svg_path: image_path('illustrations/issues.svg'),
      empty_dashboard_state_svg_path: image_path('illustrations/security-dashboard-empty-state.svg'),
      empty_state_svg_path: image_path('illustrations/operations-dashboard_empty.svg'),
      survey_request_svg_path: image_path('illustrations/security-dashboard_empty.svg'),
      operational_empty_state_svg_path: image_path('illustrations/security-dashboard_empty.svg'),
      operational_help_path: help_page_path('user/application_security/policies/index'),
      project_add_endpoint: security_projects_path,
      project_list_endpoint: security_projects_path,
      instance_dashboard_settings_path: settings_security_dashboard_path,
      vulnerabilities_export_endpoint: expose_path(api_v4_security_vulnerability_exports_path),
      scanners: VulnerabilityScanners::ListService.new(InstanceSecurityDashboard.new(current_user)).execute.to_json,
      false_positive_doc_url: help_page_path('user/application_security/vulnerabilities/index'),
      can_view_false_positive: can_view_false_positive?
    }
  end

  def can_view_false_positive?
    ::License.feature_available?(:sast_fp_reduction).to_s
  end

  def security_dashboard_unavailable_view_data
    {
      empty_state_svg_path: image_path('illustrations/security-dashboard-empty-state.svg'),
      dashboard_documentation: help_page_path('user/application_security/security_dashboard/index'),
      is_unavailable: "true"
    }
  end

  def instance_security_settings_data
    {
      is_auditor: current_user.auditor?.to_s
    }
  end
end
