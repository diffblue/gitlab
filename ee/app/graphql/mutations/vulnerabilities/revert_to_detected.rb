# frozen_string_literal: true

module Mutations
  module Vulnerabilities
    class RevertToDetected < BaseMutation
      graphql_name 'VulnerabilityRevertToDetected'

      def self.state_transition_name_past_tense
        "reverted to detected"
      end

      prepend Mutations::VulnerabilityStateTransitions

      private

      def transition_vulnerability(vulnerability, comment)
        ::Vulnerabilities::RevertToDetectedService.new(current_user, vulnerability, comment).execute
      end
    end
  end
end
