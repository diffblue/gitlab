# frozen_string_literal: true

module API
  class MergeRequestApprovalRules < ::API::Base
    include PaginationParams

    before { authenticate_non_get! }

    feature_category :source_code_management

    helpers do
      def find_merge_request_approval_rule(merge_request, id)
        merge_request.approval_rules.find(id)
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
      requires :merge_request_iid, type: Integer, desc: 'The IID of a merge request'
    end
    resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      segment ':id/merge_requests/:merge_request_iid/approval_rules' do
        desc 'Get all merge request approval rules' do
          success EE::API::Entities::MergeRequestApprovalRule
          tags %w[merge_request_approval_rules]
        end
        params do
          use :pagination
        end
        get '/', urgency: :low do
          merge_request = find_merge_request_with_access(params[:merge_request_iid])

          present paginate(merge_request.approval_rules), with: EE::API::Entities::MergeRequestApprovalRule, current_user: current_user
        end

        desc 'Create new merge request approval rules' do
          success EE::API::Entities::MergeRequestApprovalRule
          tags %w[merge_request_approval_rules]
        end
        params do
          requires :name, type: String, desc: 'The name of the approval rule'
          requires :approvals_required, type: Integer, desc: 'The number of required approvals for this rule'
          optional :approval_project_rule_id, type: Integer, desc: 'The ID of a project-level approval rule'
          optional :user_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'The user ids for this rule'
          optional :group_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'The group ids for this rule'
          optional :usernames, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'The usernames for this rule'
        end
        post do
          merge_request = find_merge_request_with_access(params[:merge_request_iid], :update_approvers)
          result = ::ApprovalRules::CreateService.new(merge_request, current_user, declared_params(include_missing: false)).execute

          if result[:status] == :success
            present result[:rule], with: EE::API::Entities::MergeRequestApprovalRule, current_user: current_user
          else
            render_api_error!(result[:message], result[:http_status] || 400)
          end
        end

        segment ':approval_rule_id' do
          desc 'Get merge request approval rule' do
            success EE::API::Entities::MergeRequestApprovalRule
            tags %w[merge_request_approval_rules]
          end
          params do
            requires :approval_rule_id, type: Integer, desc: 'The ID of a merge request approval rule'
          end
          get do
            merge_request = find_merge_request_with_access(params[:merge_request_iid])
            approval_rule = find_merge_request_approval_rule(merge_request, params[:approval_rule_id])

            present approval_rule, with: EE::API::Entities::MergeRequestApprovalRule, current_user: current_user
          end

          desc 'Update merge request approval rule' do
            success EE::API::Entities::MergeRequestApprovalRule
            tags %w[merge_request_approval_rules]
          end
          params do
            requires :approval_rule_id, type: Integer, desc: 'The ID of a merge request approval rule'
            optional :name, type: String, desc: 'The name of the approval rule'
            optional :approvals_required, type: Integer, desc: 'The number of required approvals for this rule'
            optional :user_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'The user ids for this rule'
            optional :group_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'The group ids for this rule'
            optional :usernames, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'The group ids for this rule'
            optional :remove_hidden_groups, type: Boolean, desc: 'Whether hidden groups should be removed'
          end
          put do
            merge_request = find_merge_request_with_access(params[:merge_request_iid], :update_approvers)
            params = declared_params(include_missing: false)
            approval_rule = find_merge_request_approval_rule(merge_request, params.delete(:approval_rule_id))
            result = ::ApprovalRules::UpdateService.new(approval_rule, current_user, params).execute

            if result[:status] == :success
              present result[:rule], with: EE::API::Entities::MergeRequestApprovalRule, current_user: current_user
            else
              render_api_error!(result[:message], result[:http_status] || 400)
            end
          end

          desc 'Destroy merge request approval rule' do
            success [{ code: 204 }]
            tags %w[merge_request_approval_rules]
          end
          params do
            requires :approval_rule_id, type: Integer, desc: 'The ID of a merge request approval rule'
          end
          delete do
            merge_request = find_merge_request_with_access(params[:merge_request_iid], :update_approvers)
            approval_rule = find_merge_request_approval_rule(merge_request, params[:approval_rule_id])

            destroy_conditionally!(approval_rule) do |rule|
              result = ::ApprovalRules::MergeRequestRuleDestroyService.new(rule, current_user).execute

              if result[:status] == :error
                render_api_error!(result[:message], result[:http_status] || 400)
              end
            end
          end
        end
      end
    end
  end
end
