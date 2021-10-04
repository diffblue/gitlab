# frozen_string_literal: true

module Projects::ThreatMonitoringHelper
  def threat_monitoring_alert_details_data(project, alert_iid)
    {
      'alert-id' => alert_iid,
      'project-path' => project.full_path,
      'project-id' => project.id,
      'project-issues-path' => project_issues_path(project),
      'page' => 'THREAT_MONITORING'
    }
  end
end
