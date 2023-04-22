# frozen_string_literal: true

module Types
  module MergeRequests
    class ApprovalStateType < BaseObject
      graphql_name 'MergeRequestApprovalState'
      description 'Information relating to rules that must be satisfied to merge this merge request.'
      authorize :read_merge_request

      field :approval_rules_overwritten, GraphQL::Types::Boolean,
        null: true, method: :approval_rules_overwritten?,
        description: 'Indicates if the merge request approval rules are overwritten for the merge request.'

      field :rules, [::Types::ApprovalRuleType],
        null: true, complexity: 5, method: :wrapped_approval_rules,
        description: 'List of approval rules associated with the merge request.'

      field :invalid_approvers_rules,
        [::Types::ApprovalRuleType],
        null: true,
        calls_gitaly: true,
        description: 'List of approval rules that are associated with the merge request, but invalid.'

      field :suggested_approvers, Types::UserType.connection_type,
        null: true,
        complexity: 10,
        calls_gitaly: true,
        description: 'List of suggested approvers.'

      def suggested_approvers
        object.suggested_approvers(current_user: current_user)
      end
    end
  end
end
