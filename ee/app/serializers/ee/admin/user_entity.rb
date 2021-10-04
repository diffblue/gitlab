# frozen_string_literal: true

module EE
  module Admin
    module UserEntity
      extend ActiveSupport::Concern

      prepended do
        expose :oncall_schedules, with: ::IncidentManagement::OncallScheduleEntity
        expose :escalation_policies, with: ::IncidentManagement::EscalationPolicyEntity
      end
    end
  end
end
