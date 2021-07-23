# frozen_string_literal: true

module API
  module Helpers
    module ProjectApprovalRulesHelpers
      extend Grape::API::Helpers

      params :create_project_approval_rule do
        requires :name, type: String, desc: 'The name of the approval rule'
        requires :approvals_required, type: Integer, desc: 'The number of required approvals for this rule'
        optional :rule_type, type: String, desc: 'The type of approval rule'
        optional :users, as: :user_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'The user ids for this rule'
        optional :groups, as: :group_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'The group ids for this rule'
        optional :protected_branch_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'The protected branch ids for this rule'
        optional :scanners, type: Array[String], desc: 'The security scanners to be considered by the approval rule'
      end

      params :update_project_approval_rule do
        requires :approval_rule_id, type: Integer, desc: 'The ID of an approval_rule'
        optional :name, type: String, desc: 'The name of the approval rule'
        optional :approvals_required, type: Integer, desc: 'The number of required approvals for this rule'
        optional :users, as: :user_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'The user ids for this rule'
        optional :groups, as: :group_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'The group ids for this rule'
        optional :protected_branch_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'The protected branch ids for this rule'
        optional :remove_hidden_groups, type: Boolean, desc: 'Whether hidden groups should be removed'
        optional :scanners, type: Array[String], desc: 'The security scanners to be considered by the approval rule'
      end

      params :delete_project_approval_rule do
        requires :approval_rule_id, type: Integer, desc: 'The ID of an approval_rule'
      end

      def authorize_read_project_approval_rule!
        return if can?(current_user, :admin_project, user_project)

        authorize! :create_merge_request_in, user_project
      end

      def create_project_approval_rule(present_with:)
        authorize! :admin_project, user_project

        result = ::ApprovalRules::CreateService.new(user_project, current_user, declared_params(include_missing: false)).execute

        if result[:status] == :success
          present result[:rule], with: present_with, current_user: current_user
        else
          render_api_error!(result[:message], result[:http_status] || 400)
        end
      end

      def update_project_approval_rule(present_with:)
        authorize! :admin_project, user_project

        params = declared_params(include_missing: false)
        approval_rule = user_project.approval_rules.find(params.delete(:approval_rule_id))
        result = ::ApprovalRules::UpdateService.new(approval_rule, current_user, params).execute

        if result[:status] == :success
          present result[:rule], with: present_with, current_user: current_user
        else
          render_api_error!(result[:message], result[:http_status] || 400)
        end
      end

      def destroy_project_approval_rule
        authorize! :admin_project, user_project

        approval_rule = user_project.approval_rules.find(params[:approval_rule_id])

        destroy_conditionally!(approval_rule) do |rule|
          ::ApprovalRules::ProjectRuleDestroyService.new(rule).execute
        end
      end
    end
  end
end
