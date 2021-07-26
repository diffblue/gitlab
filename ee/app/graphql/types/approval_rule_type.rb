# frozen_string_literal: true

module Types
  class ApprovalRuleType < BaseObject
    graphql_name 'ApprovalRule'
    description 'Describes a rule for who can approve merge requests.'
    authorize :read_approval_rule

    field :id,
          type: ::Types::GlobalIDType,
          null: false,
          description: 'ID of the rule.'

    field :name,
          type: GraphQL::Types::String,
          null: true,
          description: 'Name of the rule.'

    field :type,
          type: ::Types::ApprovalRuleTypeEnum,
          null: true,
          method: :rule_type,
          description: 'Type of the rule.'
  end
end
