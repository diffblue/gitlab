# frozen_string_literal: true

module EE
  module IncidentManagement
    module IssuableEscalationStatuses
      module PrepareUpdateService
        extend ::Gitlab::Utils::Override

        EE_SUPPORTED_PARAMS = %i[policy].freeze

        override :supported_params
        def supported_params
          super + EE_SUPPORTED_PARAMS
        end

        override :filter_attributes
        def filter_attributes
          super

          filter_policy
        end

        def filter_policy
          policy = params.delete(:policy)

          return unless ::Gitlab::IncidentManagement.escalation_policies_available?(project)
          return if issuable.alert_management_alert # Cannot change the policy for an alert

          if policy
            return if policy.id == escalation_status.policy_id
            if policy.project_id != issuable.project_id
              raise ::IncidentManagement::IssuableEscalationStatuses::PrepareUpdateService::InvalidParamError
            end

            # Override any provided status if setting new policy
            params[:status_event] = :trigger
          end

          params[:policy] = policy
          params[:escalations_started_at] = policy ? Time.current : nil
        end

        override :current_params
        def current_params
          strong_memoize(:current_params) do
            super.merge(
              policy: escalation_status.policy
            )
          end
        end
      end
    end
  end
end
