# frozen_string_literal: true

module EE
  module IncidentManagement
    module IssuableEscalationStatuses
      module AfterUpdateService
        extend ::Gitlab::Utils::Override

        private

        delegate :open_status?, :status_name, to: '::IncidentManagement::IssuableEscalationStatus'

        override :after_update
        def after_update
          super

          reset_pending_escalations
        end

        def reset_pending_escalations
          return unless ::Gitlab::IncidentManagement.escalation_policies_available?(project)
          return unless policy_changed? || open_status_changed?

          delete_escalations if had_policy? && had_open_status?
          create_escalations if has_policy_now? && has_open_status_now?
        end

        def policy_changed?
          escalation_status.policy_id_previously_changed?
        end

        def open_status_changed?
          return false unless escalation_status.status_previously_changed?

          had_open_status? != has_open_status_now?
        end

        def had_policy?
          escalation_status.policy_id_previously_was.present?
        end

        def has_policy_now?
          escalation_status.policy_id.present?
        end

        def had_open_status?
          open_status?(status_name(escalation_status.status_previously_was))
        end

        def has_open_status_now?
          escalation_status.open?
        end

        def delete_escalations
          ::IncidentManagement::PendingEscalations::Issue.delete_by_target(issuable)
        end

        def create_escalations
          ::IncidentManagement::PendingEscalations::IssueCreateWorker.perform_async(issuable.id)
          ::SystemNoteService.start_escalation(issuable, escalation_status.policy, current_user)
        end
      end
    end
  end
end
