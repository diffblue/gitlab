# frozen_string_literal: true

module IncidentManagement
  module OncallScheduleHelper
    def oncall_schedule_data(project)
      {
        'project-path' => project.full_path,
        'empty-oncall-schedules-svg-path' => image_path('illustrations/empty-state/empty-schedule-md.svg'),
        'timezones' => timezone_data(format: :full).to_json,
        'escalation-policies-path' => project_incident_management_escalation_policies_path(project),
        'user_can_create_schedule' => can?(current_user, :admin_incident_management_oncall_schedule, project).to_s,
        'access_level_description_path' => Gitlab::Routing.url_helpers.project_project_members_url(
          project,
          sort: 'access_level_desc'
        )
      }
    end
  end
end
