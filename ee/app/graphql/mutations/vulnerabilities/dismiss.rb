# frozen_string_literal: true

module Mutations
  module Vulnerabilities
    class Dismiss < BaseMutation
      graphql_name 'VulnerabilityDismiss'

      def self.state_transition_name_past_tense
        "dismissed"
      end

      prepend Mutations::VulnerabilityStateTransitions

      argument :dismissal_reason,
               Types::Vulnerabilities::DismissalReasonEnum,
               required: false,
               description: 'Reason why vulnerability should be dismissed.'

      def resolve(id:, comment: nil, dismissal_reason: nil)
        vulnerability = authorized_find!(id: id)
        result = transition_vulnerability(vulnerability, comment, dismissal_reason)

        {
          vulnerability: result,
          errors: result.errors.full_messages || []
        }
      end

      private

      def transition_vulnerability(vulnerability, comment, dismissal_reason)
        ::Vulnerabilities::DismissService.new(current_user, vulnerability, comment, dismissal_reason).execute
      end
    end
  end
end
