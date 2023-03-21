# frozen_string_literal: true

module Mutations
  module Vulnerabilities
    class Confirm < BaseMutation
      graphql_name 'VulnerabilityConfirm'

      def self.state_transition_name_past_tense
        "confirmed"
      end

      prepend Mutations::VulnerabilityStateTransitions

      private

      def transition_vulnerability(vulnerability, comment)
        ::Vulnerabilities::ConfirmService.new(current_user, vulnerability, comment).execute
      end
    end
  end
end
