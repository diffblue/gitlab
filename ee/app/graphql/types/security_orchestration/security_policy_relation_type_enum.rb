# frozen_string_literal: true

module Types
  module SecurityOrchestration
    class SecurityPolicyRelationTypeEnum < BaseEnum
      graphql_name 'SecurityPolicyRelationType'

      value 'DIRECT',
        description: 'Policies defined for the project only.',
        value: :direct

      value 'INHERITED',
        description: 'Policies defined for the project and project\'s ancestor groups.',
        value: :inherited
    end
  end
end
