# frozen_string_literal: true

module Types
  module SecurityOrchestration
    class SecurityPolicySourceType < BaseUnion
      graphql_name 'SecurityPolicySource'
      description 'Represents a policy source. Its fields depend on the source type.'

      possible_types SecurityOrchestration::GroupSecurityPolicySourceType,
                     SecurityOrchestration::ProjectSecurityPolicySourceType

      def self.resolve_type(object, context)
        if object[:namespace].present?
          SecurityOrchestration::GroupSecurityPolicySourceType
        else
          SecurityOrchestration::ProjectSecurityPolicySourceType
        end
      end
    end
  end
end
