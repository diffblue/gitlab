# frozen_string_literal: true

module Types
  class ApprovalRuleType < BaseObject
    graphql_name 'ApprovalRule'
    description 'Describes a rule for who can approve merge requests.'
    authorize :read_approval_rule

    present_using ::ApprovalRulePresenter

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

    field :approvals_required,
          type: GraphQL::Types::Int,
          null: true,
          description: 'Number of required approvals.'

    field :approved,
          type: GraphQL::Types::Boolean,
          method: :approved?,
          null: true,
          calls_gitaly: true,
          description: 'Indicates if the rule is satisfied.'

    field :overridden,
          type: GraphQL::Types::Boolean,
          method: :overridden?,
          null: true,
          description: 'Indicates if the rule was overridden for the merge request.'

    field :section,
          type: GraphQL::Types::String,
          null: true,
          description: 'Named section of the Code Owners file that the rule applies to.'

    field :contains_hidden_groups,
          type: GraphQL::Types::Boolean,
          method: :contains_hidden_groups?,
          null: true,
          description: 'Indicates if the rule contains approvers from a hidden group.'

    field :source_rule,
          type: self,
          null: true,
          description: 'Source rule used to create the rule.'

    field :eligible_approvers,
          type: [::Types::UserType],
          method: :approvers,
          null: true,
          description: 'List of all users eligible to approve the merge request (defined explicitly and from associated groups).'

    field :users,
          type: ::Types::UserType.connection_type,
          null: true,
          description: 'List of users added as approvers for the rule.'

    field :approved_by,
          type: ::Types::UserType.connection_type,
          method: :approved_approvers,
          null: true,
          description: 'List of users defined in the rule that approved the merge request.'

    field :groups,
          type: ::Types::GroupType.connection_type,
          null: true,
          description: 'List of groups added as approvers for the rule.'

    field :commented_by,
          type: ::Types::UserType.connection_type,
          method: :commented_approvers,
          null: true,
          description: 'List of users, defined in the rule, who commented on the merge request.'

    field :invalid,
          type: GraphQL::Types::Boolean,
          method: :invalid_rule?,
          null: true,
          description: 'Indicates if the rule is invalid and cannot be approved.'

    field :allow_merge_when_invalid,
          type: GraphQL::Types::Boolean,
          method: :allow_merge_when_invalid?,
          null: true,
          description: 'Indicates if the rule can be ignored if it is invalid.'
  end
end
