# frozen_string_literal: true

module API
  class MergeRequestApprovalSettings < ::API::Base
    feature_category :source_code_management

    before do
      authenticate!
    end

    helpers do
      params :merge_request_approval_settings do
        optional :allow_author_approval, type: Boolean, desc: 'Allow authors to self-approve merge requests', allow_blank: false
        optional :allow_committer_approval, type: Boolean, desc: 'Allow committers to approve merge requests', allow_blank: false
        optional :allow_overrides_to_approver_list_per_merge_request,
          type: Boolean, desc: 'Allow overrides to approver list per merge request', allow_blank: false
        optional :retain_approvals_on_push, type: Boolean, desc: 'Retain approval count on a new push', allow_blank: false
        optional :selective_code_owner_removals, type: Boolean, desc: 'Reset approvals from Code Owners if their files changed', allow_blank: false
        optional :require_password_to_approve,
          type: Boolean, desc: 'Require approver to authenticate before approving', allow_blank: false

        at_least_one_of :allow_author_approval,
          :allow_committer_approval,
          :allow_overrides_to_approver_list_per_merge_request,
          :retain_approvals_on_push,
          :selective_code_owner_removals,
          :require_password_to_approve
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before do
        authorize! :admin_merge_request_approval_settings, user_project
      end
      segment ':id/merge_request_approval_setting' do
        desc 'Get project-level MR approval settings' do
          success code: 200, model: ::API::Entities::MergeRequestApprovalSetting
          failure [
            { code: 403, message: 'Forbidden' }
          ]
          tags %w[merge_request_approval_setting]
        end
        get '/', urgency: :medium do
          group = user_project.group.present? ? user_project.root_ancestor : nil
          setting = ComplianceManagement::MergeRequestApprovalSettings::Resolver.new(group, project: user_project).execute

          present setting, with: ::API::Entities::MergeRequestApprovalSetting
        end
        desc 'Update existing merge request approval setting' do
          success code: 200, model: ::API::Entities::MergeRequestApprovalSetting
          failure [
            { code: 400, message: 'Validation error' },
            { code: 403, message: 'Forbidden' }
          ]
          tags %w[merge_request_approval_setting]
        end
        params do
          use :merge_request_approval_settings
        end
        put do
          setting_params = declared_params(include_missing: false)

          response = ::MergeRequestApprovalSettings::UpdateService
                       .new(container: user_project, current_user: current_user, params: setting_params).execute

          if response.success?
            group = user_project.group.present? ? user_project.root_ancestor : nil

            setting = ComplianceManagement::MergeRequestApprovalSettings::Resolver.new(group, project: user_project).execute

            present setting, with: ::API::Entities::MergeRequestApprovalSetting
          else
            render_api_error!(response.message, :bad_request)
          end
        end
      end
    end

    params do
      requires :id, type: String, desc: 'The ID or URL-encoded path of a group'
    end
    resource :groups, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before do
        authorize! :admin_merge_request_approval_settings, user_group
      end
      segment ':id/merge_request_approval_setting' do
        desc 'Get group merge request approval setting' do
          success code: 200, model: ::API::Entities::MergeRequestApprovalSetting
          failure [
            { code: 403, message: 'Forbidden' }
          ]
          tags %w[merge_request_approval_setting]
        end
        get do
          setting = ComplianceManagement::MergeRequestApprovalSettings::Resolver.new(user_group).execute

          present setting, with: ::API::Entities::MergeRequestApprovalSetting
        end

        desc 'Update existing merge request approval setting' do
          success code: 200, model: ::API::Entities::MergeRequestApprovalSetting
          failure [
            { code: 400, message: 'Validation error' },
            { code: 403, message: 'Forbidden' }
          ]
          tags %w[merge_request_approval_setting]
        end
        params do
          use :merge_request_approval_settings
        end
        put do
          setting_params = declared_params(include_missing: false)

          response = ::MergeRequestApprovalSettings::UpdateService
            .new(container: user_group, current_user: current_user, params: setting_params).execute

          if response.success?
            setting = ComplianceManagement::MergeRequestApprovalSettings::Resolver.new(user_group).execute

            present setting, with: ::API::Entities::MergeRequestApprovalSetting
          else
            render_api_error!(response.message, :bad_request)
          end
        end
      end
    end
  end
end
