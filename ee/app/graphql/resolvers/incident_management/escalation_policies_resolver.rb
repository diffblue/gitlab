# frozen_string_literal: true

module Resolvers
  module IncidentManagement
    class EscalationPoliciesResolver < BaseResolver
      include LooksAhead

      alias_method :project, :object

      type Types::IncidentManagement::EscalationPolicyType.connection_type, null: true

      argument :name,
               GraphQL::Types::String,
               required: false,
               description: 'Fuzzy search by escalation policy name.'

      when_single do
        argument :id,
                 ::Types::GlobalIDType[::IncidentManagement::EscalationPolicy],
                 required: true,
                 description: 'ID of the escalation policy.',
                 prepare: ->(id, ctx) { id.model_id }
      end

      def resolve_with_lookahead(name: nil, **args)
        context[:execution_time] = Time.current

        apply_lookahead(
          ::IncidentManagement::EscalationPoliciesFinder.new(
            current_user,
            project,
            { name_search: name, **args }
          ).execute
        )
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
