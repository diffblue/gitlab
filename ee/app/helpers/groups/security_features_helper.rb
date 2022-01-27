# frozen_string_literal: true

module Groups::SecurityFeaturesHelper
  def group_level_compliance_dashboard_available?(group)
    group.licensed_feature_available?(:group_level_compliance_dashboard) &&
    can?(current_user, :read_group_compliance_dashboard, group)
  end

  def authorize_compliance_dashboard!
    render_404 unless group_level_compliance_dashboard_available?(group)
  end

  def group_level_credentials_inventory_available?(group)
    can?(current_user, :read_group_credentials_inventory, group) &&
    group.licensed_feature_available?(:credentials_inventory) &&
    group.enforced_group_managed_accounts?
  end

  def group_level_security_dashboard_data(group)
    {
      projects_endpoint: expose_url(api_v4_groups_projects_path(id: group.id)),
      group_full_path: group.full_path,
      no_vulnerabilities_svg_path: image_path('illustrations/issues.svg'),
      empty_state_svg_path: image_path('illustrations/security-dashboard-empty-state.svg'),
      operational_empty_state_svg_path: image_path('illustrations/security-dashboard_empty.svg'),
      operational_help_path: help_page_path('user/application_security/policies/index'),
      survey_request_svg_path: image_path('illustrations/security-dashboard_empty.svg'),
      sbom_survey_svg_path: image_path('illustrations/monitoring/tracing.svg'),
      dashboard_documentation: help_page_path('user/application_security/security_dashboard/index'),
      vulnerabilities_export_endpoint: expose_path(api_v4_security_groups_vulnerability_exports_path(id: group.id)),
      scanners: VulnerabilityScanners::ListService.new(group).execute.to_json,
      can_admin_vulnerability: can?(current_user, :admin_vulnerability, group).to_s,
      false_positive_doc_url: help_page_path('user/application_security/vulnerabilities/index'),
      can_view_false_positive: group.licensed_feature_available?(:sast_fp_reduction).to_s,
      has_projects: group.projects.any?.to_s
    }
  end

  def group_security_discover_data(group)
    content = pql_three_cta_test_experiment_candidate?(group.root_ancestor) ? 'discover-group-security-pqltest' : 'discover-group-security'

    data = {
      group: {
        id: group.id,
        name: group.name
      },
      link: {
        main: new_trial_registration_path(glm_source: 'gitlab.com', glm_content: content),
        secondary: group_billings_path(group.root_ancestor, source: content)
      }
    }

    data.merge(hand_raise_props(group.root_ancestor, glm_content: content))
  end
end
