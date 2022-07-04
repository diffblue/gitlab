# frozen_string_literal: true

module API
  class ProjectApprovalRules < ::API::Base
    include PaginationParams

    before { authenticate! }

    helpers ::API::Helpers::ProjectApprovalRulesHelpers

    feature_category :source_code_management

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      segment ':id/approval_rules' do
        desc 'Get all project approval rules' do
          success EE::API::Entities::ProjectApprovalRule
        end
        params do
          use :pagination
        end
        get do
          authorize_read_project_approval_rule!

          if Feature.enabled?(:approval_rules_pagination, user_project)
            present paginate(::Kaminari.paginate_array(user_project.visible_approval_rules)), with: EE::API::Entities::ProjectApprovalRule, current_user: current_user
          else
            present user_project.visible_approval_rules, with: EE::API::Entities::ProjectApprovalRule, current_user: current_user
          end
        end

        desc 'Create new project approval rule' do
          success EE::API::Entities::ProjectApprovalRule
        end
        params do
          use :create_project_approval_rule
        end
        post do
          create_project_approval_rule(present_with: EE::API::Entities::ProjectApprovalRule)
        end

        segment ':approval_rule_id' do
          desc 'Get a single approval rule' do
            success EE::API::Entities::ProjectApprovalRule
          end
          get do
            authorize_read_project_approval_rule!

            approval_rule = user_project.approval_rules.find(params[:approval_rule_id])

            present approval_rule, with: EE::API::Entities::ProjectApprovalRule, current_user: current_user
          end

          desc 'Update project approval rule' do
            success EE::API::Entities::ProjectApprovalRule
          end
          params do
            use :update_project_approval_rule
          end
          put do
            update_project_approval_rule(present_with: EE::API::Entities::ProjectApprovalRule)
          end

          desc 'Destroy project approval rule'
          params do
            use :delete_project_approval_rule
          end
          delete do
            destroy_project_approval_rule
          end
        end
      end
    end
  end
end
