# frozen_string_literal: true

module IncidentManagement
  class EscalationPolicyEntity < Grape::Entity
    include ::Gitlab::Routing

    expose :name
    expose :url do |policy|
      project_incident_management_escalation_policies_url(policy.project)
    end

    expose :project_name
    expose :project_url do |policy|
      project_url(policy.project)
    end
  end
end
