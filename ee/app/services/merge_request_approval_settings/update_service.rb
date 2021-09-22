# frozen_string_literal: true

module MergeRequestApprovalSettings
  class UpdateService < BaseContainerService
    def execute
      return ServiceResponse.error(message: 'Insufficient permissions') unless allowed?

      if container.is_a?(Group)
        setting = GroupMergeRequestApprovalSetting.find_or_initialize_by_group(container)
        setting.assign_attributes(params)

        if setting.save
          ServiceResponse.success(payload: setting)
        else
          ServiceResponse.error(message: setting.errors.messages)
        end
      elsif container.is_a?(Project)
        resolved_params = {
          merge_requests_author_approval: params[:allow_author_approval],
          merge_requests_disable_committers_approval: !params[:allow_committer_approval],
          disable_overriding_approvers_per_merge_request: !params[:allow_overrides_to_approver_list_per_merge_request],
          reset_approvals_on_push: !params[:retain_approvals_on_push],
          require_password_to_approve: params[:require_password_to_approve]
        }
        result = ::Projects::UpdateService.new(container, current_user, resolved_params).execute

        if result[:status] == :success
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
  end
end
