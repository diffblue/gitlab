# frozen_string_literal: true

module API
  class ProjectApprovalSettings < ::API::Base
    before { authenticate! }
    before { check_feature_availability }

    helpers ::API::Helpers::ProjectApprovalRulesHelpers

    feature_category :source_code_management

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      segment ':id/approval_settings' do
        desc 'Get all project approval rules' do
          detail 'Private API subject to change'
          success EE::API::Entities::ProjectApprovalSettings
          tags %w[project_approval_rules]
        end
        params do
          optional :target_branch, type: String, desc: 'Branch that scoped approval rules apply to'
        end
        get do
          authorize_read_project_approval_rule!

          present(
            user_project,
            with: EE::API::Entities::ProjectApprovalSettings,
            current_user: current_user,
            target_branch: declared_params[:target_branch]
          )
        end

        segment 'rules' do
          desc 'Create new approval rule' do
            detail 'Private API subject to change'
            success EE::API::Entities::ProjectApprovalSettingRule
            tags %w[project_approval_rules]
          end
          params do
            use :create_project_approval_rule
          end
          post do
            create_project_approval_rule(present_with: EE::API::Entities::ProjectApprovalSettingRule)
          end

          segment ':approval_rule_id' do
            desc 'Update approval rule' do
              detail 'Private API subject to change'
              success EE::API::Entities::ProjectApprovalSettingRule
              tags %w[project_approval_rules]
            end
            params do
              use :update_project_approval_rule
            end
            put do
              update_project_approval_rule(present_with: EE::API::Entities::ProjectApprovalSettingRule)
            end

            desc 'Delete an approval rule' do
              detail 'Private API subject to change'
              success [{ code: 204 }]
              tags %w[project_approval_rules]
            end
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
end
