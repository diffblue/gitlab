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
        optional :require_password_to_approve,
                 type: Boolean, desc: 'Require approver to authenticate before approving', allow_blank: false

        at_least_one_of :allow_author_approval,
                        :allow_committer_approval,
                        :allow_overrides_to_approver_list_per_merge_request,
                        :retain_approvals_on_push,
                        :require_password_to_approve
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before do
        authorize! :admin_merge_request_approval_settings, user_project
      end
      segment ':id/merge_request_approval_setting' do
        desc 'Get project-level MR approval settings' do
          detail 'This feature was introduced in 14.3 behind the :group_merge_request_approval_settings_feature_flag'
          success EE::API::Entities::MergeRequestApprovalSettings
        end
        get '/', urgency: :medium do
          not_found! unless ::Feature.enabled?(:group_merge_request_approval_settings_feature_flag, user_project.root_ancestor, default_enabled: :yaml)

          group = user_project.group.present? ? user_project.root_ancestor : nil
          setting = ComplianceManagement::MergeRequestApprovalSettings::Resolver.new(group, project: user_project).execute

          present setting, with: ::API::Entities::MergeRequestApprovalSetting
        end
        desc 'Update existing merge request approval setting' do
          detail 'This feature is gated by the :group_merge_request_approval_settings_feature_flag'
          success ::API::Entities::MergeRequestApprovalSetting
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
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before do
        not_found! unless ::Feature.enabled?(:group_merge_request_approval_settings_feature_flag, user_group, default_enabled: :yaml)

        authorize! :admin_merge_request_approval_settings, user_group
      end
      segment ':id/merge_request_approval_setting' do
        desc 'Get group merge request approval setting' do
          detail 'This feature is gated by the :group_merge_request_approval_settings_feature_flag'
          success ::API::Entities::MergeRequestApprovalSetting
        end
        get do
          setting = ComplianceManagement::MergeRequestApprovalSettings::Resolver.new(user_group).execute

          present setting, with: ::API::Entities::MergeRequestApprovalSetting
        end

        desc 'Update existing merge request approval setting' do
          detail 'This feature is gated by the :group_merge_request_approval_settings_feature_flag'
          success ::API::Entities::MergeRequestApprovalSetting
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
