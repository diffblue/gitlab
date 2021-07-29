# frozen_string_literal: true

module Resolvers
  module IncidentManagement
    class EscalationPoliciesResolver < BaseResolver
      include LooksAhead

      alias_method :project, :object

      type Types::IncidentManagement::EscalationPolicyType.connection_type, null: true

      when_single do
        argument :id,
                 ::Types::GlobalIDType[::IncidentManagement::EscalationPolicy],
                 required: true,
                 description: 'ID of the escalation policy.',
                 prepare: ->(id, ctx) { id.model_id }
      end

      def resolve_with_lookahead(**args)
        apply_lookahead(::IncidentManagement::EscalationPoliciesFinder.new(current_user, project, args).execute)
      end

      private

      def preloads
        {
          rules: [:active_rules]
        }
      end
    end
  end
end
