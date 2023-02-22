# frozen_string_literal: true

module VulnerabilitiesHelper
  FINDING_FIELDS = %i[metadata identifiers name issue_feedback merge_request_feedback project project_fingerprint scanner uuid details dismissal_feedback false_positive state_transitions issue_links merge_request_links].freeze

  def vulnerability_details_json(vulnerability, pipeline)
    vulnerability_details(vulnerability, pipeline).to_json
  end

  def vulnerability_details(vulnerability, pipeline)
    return unless vulnerability

    result = {
      timestamp: Time.now.to_i,
      new_issue_url: new_issue_url_for(vulnerability),
      create_jira_issue_url: create_jira_issue_url_for(vulnerability),
      related_jira_issues_path: project_integrations_jira_issues_path(vulnerability.project, vulnerability_ids: [vulnerability.id]),
      jira_integration_settings_path: edit_project_settings_integration_path(vulnerability.project, ::Integrations::Jira),
      create_mr_url: create_vulnerability_feedback_merge_request_path(vulnerability.finding.project),
      discussions_url: discussions_project_security_vulnerability_path(vulnerability.project, vulnerability),
      notes_url: project_security_vulnerability_notes_path(vulnerability.project, vulnerability),
      related_issues_help_path: help_page_path('user/application_security/vulnerabilities', anchor: 'linking-a-vulnerability-to-issues'),
      pipeline: vulnerability_pipeline_data(pipeline),
      can_modify_related_issues: current_user.can?(:admin_vulnerability_issue_link, vulnerability),
      issue_tracking_help_path: help_page_path('user/project/settings', anchor: 'sharing-and-permissions'),
      permissions_help_path: help_page_path('user/permissions', anchor: 'project-members-permissions'),
      dismissal_descriptions: dismissal_descriptions
    }

    result.merge(vulnerability_data(vulnerability), vulnerability_finding_data(vulnerability))
  end

  def dismissal_descriptions
    Vulnerabilities::DismissalReasonEnum.translated_descriptions
  end

  def new_issue_url_for(vulnerability)
    return unless vulnerability.project.issues_enabled?

    new_project_issue_path(vulnerability.project, { vulnerability_id: vulnerability.id })
  end

  # This method can be called with an instance of the following models;
  # - Vulnerability
  # - Vulnerabilities::Finding
  # - Security::Finding
  #
  def create_jira_issue_url_for(vulnerability)
    return unless vulnerability.project.configured_to_create_issues_from_vulnerabilities?

    decorated_vulnerability = vulnerability.present
    summary = _('Investigate vulnerability: %{title}') % { title: decorated_vulnerability.title }
    description = ApplicationController.render(
      template: 'vulnerabilities/jira_issue_description',
      formats: :md,
      locals: { vulnerability: decorated_vulnerability }
    )

    vulnerability.project.jira_integration.new_issue_url_with_predefined_fields(summary, description)
  end

  def vulnerability_pipeline_data(pipeline)
    return unless pipeline

    {
      id: pipeline.id,
      created_at: pipeline.created_at.iso8601,
      url: pipeline_path(pipeline),
      source_branch: pipeline.ref
    }
  end

  def vulnerability_data(vulnerability)
    VulnerabilitySerializer.new.represent(vulnerability)
  end

  def vulnerability_data_with_category(vulnerability)
    vulnerability_data(vulnerability).merge({ category: vulnerability.report_type })
  end

  def vulnerability_finding_data(vulnerability)
    data = Vulnerabilities::FindingSerializer.new(current_user: current_user).represent(vulnerability.finding, only: FINDING_FIELDS)
    data[:location].merge!('blob_path' => vulnerability.blob_path).compact!
    data[:description_html] = markdown(vulnerability.present.description)
    data[:solution_html] = markdown(vulnerability.present.solution)
    data
  end

  def vulnerability_scan_data?(vulnerability)
    vulnerability.scanner.present? || vulnerability.scan.present?
  end
end
