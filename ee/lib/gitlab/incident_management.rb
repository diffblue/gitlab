# frozen_string_literal: true

module Gitlab
  module IncidentManagement
    def self.oncall_schedules_available?(project)
      project.licensed_feature_available?(:oncall_schedules)
    end

    def self.escalation_policies_available?(project)
      oncall_schedules_available?(project) && project.licensed_feature_available?(:escalation_policies)
    end

    def self.timeline_events_available?(project)
      project.licensed_feature_available?(:incident_timeline_events)
    end
  end
end
