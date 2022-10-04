# frozen_string_literal: true

module Gitlab
  module IncidentManagement
    def self.oncall_schedules_available?(project)
      project.licensed_feature_available?(:oncall_schedules)
    end

    def self.escalation_policies_available?(project)
      oncall_schedules_available?(project) && project.licensed_feature_available?(:escalation_policies)
    end

    def self.issuable_resource_links_available?(project)
      project.licensed_feature_available?(:issuable_resource_links)
    end
  end
end
