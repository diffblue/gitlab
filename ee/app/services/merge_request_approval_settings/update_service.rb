# frozen_string_literal: true

module MergeRequestApprovalSettings
  class UpdateService < BaseContainerService
    def execute
      return ServiceResponse.error(message: 'Insufficient permissions') unless allowed?

      case container
      when Group
        setting = GroupMergeRequestApprovalSetting.find_or_initialize_by_group(container)
        setting.assign_attributes(params.except(:selective_code_owner_removals))

        if setting.save
          log_audit_event(setting)
          run_compliance_standards_checks
          ServiceResponse.success(payload: setting)
        else
          ServiceResponse.error(message: setting.errors.messages)
        end
      when Project
        resolved_params = {
          merge_requests_author_approval: params[:allow_author_approval],
          merge_requests_disable_committers_approval: !params[:allow_committer_approval],
          disable_overriding_approvers_per_merge_request: !params[:allow_overrides_to_approver_list_per_merge_request],
          reset_approvals_on_push: !params[:retain_approvals_on_push],
          project_setting_attributes: {
            selective_code_owner_removals: params[:selective_code_owner_removals] || false
          },
          require_password_to_approve: params[:require_password_to_approve]
        }

        approval_removal_settings = MergeRequest::ApprovalRemovalSettings.new(
          container,
          !params[:retain_approvals_on_push],
          params[:selective_code_owner_removals]
        )

        unless approval_removal_settings.valid?
          return ServiceResponse.error(message:
            _('selective_code_owner_removals can only be enabled when retain_approvals_on_push is enabled'))
        end

        result = ::Projects::UpdateService.new(container, current_user, resolved_params).execute

        if result[:status] == :success
          run_compliance_standards_checks
          ServiceResponse.success(payload: container)
        else
          ServiceResponse.error(message: container.errors.messages)
        end
      end
    end

    private

    def allowed?
      can?(current_user, :admin_merge_request_approval_settings, container)
    end

    def log_audit_event(setting)
      Audit::GroupMergeRequestApprovalSettingChangesAuditor.new(current_user, setting, params).execute
    end

    def run_compliance_standards_checks
      return unless params.include?(:allow_author_approval) || params.include?(:allow_committer_approval)

      if group_container?
        run_compliance_checks_for_group
      else
        run_compliance_checks_for_project
      end
    end

    def run_compliance_checks_for_group
      return unless Feature.enabled?(:compliance_adherence_report, container)

      ::ComplianceManagement::Standards::Gitlab::PreventApprovalByAuthorGroupWorker
        .perform_async({ 'group_id' => container.id, 'user_id' => current_user&.id })

      ::ComplianceManagement::Standards::Gitlab::PreventApprovalByCommitterGroupWorker
        .perform_async({ 'group_id' => container.id, 'user_id' => current_user&.id })
    end

    def run_compliance_checks_for_project
      return unless Feature.enabled?(:compliance_adherence_report, container.root_ancestor)

      ::ComplianceManagement::Standards::Gitlab::PreventApprovalByAuthorWorker
        .perform_async({ 'project_id' => container.id, 'user_id' => current_user&.id })

      ::ComplianceManagement::Standards::Gitlab::PreventApprovalByCommitterWorker
        .perform_async({ 'project_id' => container.id, 'user_id' => current_user&.id })
    end
  end
end
