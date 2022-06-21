# frozen_string_literal: true

module Types
  module SecurityOrchestration
    class SecurityPolicyRelationTypeEnum < BaseEnum
      graphql_name 'SecurityPolicyRelationType'

      value 'DIRECT',
        description: 'Policies defined for the project/group only.',
        value: :direct

      value 'INHERITED',
        description: 'Policies defined for the project/group and ancestor groups.',
        value: :inherited

      value 'INHERITED_ONLY',
        description: 'Policies defined for the project/group\'s ancestor groups only.',
        value: :inherited_only
    end
  end
end
