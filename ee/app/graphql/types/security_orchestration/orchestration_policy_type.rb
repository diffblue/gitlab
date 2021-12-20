# frozen_string_literal: true

module Types
  module SecurityOrchestration
    module OrchestrationPolicyType
      include Types::BaseInterface

      field :description, GraphQL::Types::String, null: false, description: 'Description of the policy.'
      field :enabled, GraphQL::Types::Boolean, null: false, description: 'Indicates whether this policy is enabled.'
      field :name, GraphQL::Types::String, null: false, description: 'Name of the policy.'
      field :updated_at, Types::TimeType, null: false, description: 'Timestamp of when the policy YAML was last updated.'
      field :yaml, GraphQL::Types::String, null: false, description: 'YAML definition of the policy.'
    end
  end
end
