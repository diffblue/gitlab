# frozen_string_literal: true

module ExternalStatusChecks
  class UpdateService < BaseService
    def execute
      return unauthorized_error_response unless current_user.can?(:admin_project, container)

      if with_audit_logged(rule, 'update_status_check') { rule.update(resource_params) }
        log_audit_event
        ServiceResponse.success(payload: { rule: rule })
      else
        ServiceResponse.error(message: 'Failed to update rule',
                              payload: { errors: rule.errors.full_messages },
                              http_status: :unprocessable_entity)
      end
    end

    private

    def resource_params
      params.slice(:name, :external_url, :protected_branch_ids)
    end

    def rule
      @rule ||= container.external_status_checks.find(params[:check_id])
    end

    def unauthorized_error_response
      ServiceResponse.error(
        message: 'Failed to update rule',
        payload: { errors: ['Not allowed'] },
        http_status: :unauthorized
      )
    end

    def log_audit_event
      Audit::ExternalStatusCheckChangesAuditor.new(current_user, rule).execute
    end
  end
end
