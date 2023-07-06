# frozen_string_literal: true

module Mutations
  module MergeRequests
    class UpdateApprovalRule < Base
      graphql_name 'MergeRequestUpdateApprovalRule'

      argument :approvals_required,
        GraphQL::Types::Int,
        required: true,
        description: 'Number of required approvals for a given rule.'

      argument :approval_rule_id,
        GraphQL::Types::Int,
        required: true,
        description: 'ID of an approval rule.'

      argument :name,
        GraphQL::Types::String,
        required: true,
        description: 'Name of the approval rule.'

      argument :group_ids,
        [GraphQL::Types::String],
        required: false,
        default_value: [],
        description: 'IDs of groups as approvers.'

      argument :user_ids,
        [GraphQL::Types::String],
        required: false,
        default_value: [],
        description: 'IDs of users as approvers.'

      argument :remove_hidden_groups,
        GraphQL::Types::Boolean,
        required: false,
        default_value: false,
        description: 'Whether hidden groups should be removed.'

      authorize :update_approvers

      def resolve(**params)
        resource = authorized_find!(project_path: params.delete(:project_path),
          iid: params.delete(:iid))
        approval_rule = find_merge_request_approval_rule(resource, params.delete(:approval_rule_id))

        ::ApprovalRules::UpdateService.new(approval_rule, current_user, params).execute

        {
          approval_rule.class.name.underscore.to_sym => approval_rule,
          errors: errors_on_object(resource)
        }
      end

      private

      def find_merge_request_approval_rule(merge_request, id)
        merge_request.approval_rules.find(id)
      end
    end
  end
end
