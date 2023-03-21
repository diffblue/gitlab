# frozen_string_literal: true

module Mutations
  module Vulnerabilities
    class Resolve < BaseMutation
      graphql_name 'VulnerabilityResolve'

      def self.state_transition_name_past_tense
        "resolved"
      end

      prepend Mutations::VulnerabilityStateTransitions

      private

      def transition_vulnerability(vulnerability, comment)
        ::Vulnerabilities::ResolveService.new(current_user, vulnerability, comment).execute
      end
    end
  end
end
