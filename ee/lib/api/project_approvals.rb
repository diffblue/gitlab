# frozen_string_literal: true

module API
  class ProjectApprovals < ::API::Base
    feature_category :source_code_management

    before { authenticate! }

    helpers do
      def filter_forbidden_param(params, permission, param)
        can?(current_user, permission, user_project) ? params : params.except(param)
      end

      def filter_params(params)
        params
          .then { |params| filter_forbidden_param(params, :modify_merge_request_committer_setting, :merge_requests_disable_committers_approval) }
          .then { |params| filter_forbidden_param(params, :modify_approvers_rules, :disable_overriding_approvers_per_merge_request) }
          .then { |params| filter_forbidden_param(params, :modify_merge_request_author_setting, :merge_requests_author_approval) }
      end

      def extract_project_settings(project_params)
        return project_params if project_params[:selective_code_owner_removals].nil?

        selective_code_owner_removals = project_params.delete(:selective_code_owner_removals)
        project_params.merge(project_setting_attributes: { selective_code_owner_removals: selective_code_owner_removals })
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      segment ':id/approvals' do
        desc 'Get all project approvers and related configuration' do
          detail 'This feature was introduced in 10.6'
          success EE::API::Entities::ApprovalSettings
          tags %w[project_approvals]
        end
        get '/', urgency: :low do
          # If the project is archived, the project admin should still be able to read the approvers
          authorize!(:read_approvers, user_project) unless can?(current_user, :admin_project, user_project)

          present user_project.present(current_user: current_user), with: EE::API::Entities::ApprovalSettings
        end

        desc 'Change approval-related configuration' do
          detail 'This feature was introduced in 10.6'
          success EE::API::Entities::ApprovalSettings
          tags %w[project_approvals]
        end
        params do
          optional :approvals_before_merge, type: Integer, desc: 'The amount of approvals required before an MR can be merged'
          optional :reset_approvals_on_push, type: Boolean, desc: 'Should the approval count be reset on a new push'
          optional :selective_code_owner_removals, type: Boolean, desc: 'Reset approvals from Code Owners if their files changed'
          optional :disable_overriding_approvers_per_merge_request, type: Boolean, desc: 'Should MRs be able to override approvers and approval count'
          optional :merge_requests_author_approval, type: Boolean, desc: 'Should merge request authors be able to self approve merge requests; `true` means authors cannot self approve'
          optional :merge_requests_disable_committers_approval, type: Boolean, desc: 'Should committers be able to self approve merge requests'
          optional :require_password_to_approve, type: Boolean, desc: 'Should approvers authenticate via password before adding approval'
          at_least_one_of :approvals_before_merge, :reset_approvals_on_push, :selective_code_owner_removals, :disable_overriding_approvers_per_merge_request, :merge_requests_author_approval, :merge_requests_disable_committers_approval, :require_password_to_approve
        end
        post '/' do
          authorize! :update_approvers, user_project

          declared_params = declared(params, include_missing: false, include_parent_namespaces: false)
          project_params = filter_params(declared_params)

          approval_removal_settings = MergeRequest::ApprovalRemovalSettings.new(
            user_project,
            project_params[:reset_approvals_on_push],
            project_params[:selective_code_owner_removals]
          )
          break render_validation_error!(approval_removal_settings) unless approval_removal_settings.valid?

          project_params = extract_project_settings(project_params)
          result = ::Projects::UpdateService.new(user_project, current_user, project_params).execute

          if result[:status] == :success
            present user_project.present(current_user: current_user), with: EE::API::Entities::ApprovalSettings
          else
            render_validation_error!(user_project)
          end
        end
      end
    end
  end
end
