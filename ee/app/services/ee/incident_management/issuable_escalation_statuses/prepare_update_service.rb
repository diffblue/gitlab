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
          return unless params.include?(:policy)

          policy = params.delete(:policy)
          return unless policies_permitted?

          policy ? set_policy(policy) : unset_policy
        end

        def policies_permitted?
          ::Gitlab::IncidentManagement.escalation_policies_available?(project)
        end

        def set_policy(policy)
          return if policy.id == escalation_status.policy_id

          unless policy.project_id == issuable.project_id
            add_param_error(:policy)
            return
          end

          params[:policy] = policy
          params[:escalations_started_at] = Time.current
          params[:status_event] = :trigger # Override any provided status if setting new policy
        end

        def unset_policy
          params[:policy] = nil
          params[:escalations_started_at] = nil
        end

        override :current_params
        def current_params
          strong_memoize(:current_params) do
            super.merge(
              policy: escalation_status.policy,
              escalations_started_at: escalation_status.escalations_started_at
            )
          end
        end
      end
    end
  end
end
