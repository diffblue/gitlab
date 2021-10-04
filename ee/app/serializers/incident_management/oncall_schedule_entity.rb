# frozen_string_literal: true

module IncidentManagement
  class OncallScheduleEntity < Grape::Entity
    include Gitlab::Routing

    expose :name
    expose :schedule_url do |schedule| # for backwards compatibility
      project_incident_management_oncall_schedules_url(schedule.project)
    end
    expose :url do |schedule|
      project_incident_management_oncall_schedules_url(schedule.project)
    end

    expose :project_name
    expose :project_url do |schedule|
      project_url(schedule.project)
    end
  end
end
