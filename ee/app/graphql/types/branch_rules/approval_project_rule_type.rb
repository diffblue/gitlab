# frozen_string_literal: true

module Types
  module BranchRules
    class ApprovalProjectRuleType < BaseObject
      graphql_name 'ApprovalProjectRule'
      description 'Describes a project approval rule for who can approve merge requests.'
      authorize :read_approval_rule

      present_using ::ApprovalRulePresenter

      field :id,
            type: ::Types::GlobalIDType,
            null: false,
            description: 'ID of the rule.'

      field :name,
            type: GraphQL::Types::String,
            null: false,
            description: 'Name of the rule.'

      field :type,
            type: ::Types::ApprovalRuleTypeEnum,
            null: false,
            method: :rule_type,
            description: 'Type of the rule.'

      field :approvals_required,
            type: GraphQL::Types::Int,
            null: false,
            description: 'Number of required approvals.'

      field :eligible_approvers,
            type: ::Types::UserType.connection_type,
            method: :approvers,
            null: true,
            description: 'List of users eligible to approve merge requests.'
    end
  end
end
