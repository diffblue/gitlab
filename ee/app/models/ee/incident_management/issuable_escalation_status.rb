# frozen_string_literal: true

module EE
  module IncidentManagement
    module IssuableEscalationStatus
      extend ActiveSupport::Concern

      prepended do
        belongs_to :policy, optional: true, class_name: '::IncidentManagement::EscalationPolicy'

        validate :presence_or_absence_of_policy_attrs

        state_machine :status, initial: :triggered do
          before_transition to: :triggered do |escalation_status|
            escalation_status.escalations_started_at = escalation_status.policy_id ? Time.current : nil
          end
        end

        private

        def presence_or_absence_of_policy_attrs
          if policy_id.present? ^ escalations_started_at.present?
            errors.add(:policy, 'must be set with escalations_started_at')
          end
        end
      end
    end
  end
end
