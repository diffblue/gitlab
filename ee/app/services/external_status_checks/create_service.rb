# frozen_string_literal: true

module ExternalStatusChecks
  class CreateService < BaseService
    def execute
      return ServiceResponse.error(message: 'Failed to create rule', payload: { errors: ['Not allowed'] }, http_status: :unauthorized) unless current_user.can?(:admin_project, container)

      rule = container.external_status_checks.new(name: params[:name],
                                                  project: container,
                                                  external_url: params[:external_url],
                                                  protected_branch_ids: params[:protected_branch_ids])

      if with_audit_logged(rule, 'create_status_check') { rule.save }
        ServiceResponse.success(payload: { rule: rule })
      else
        ServiceResponse.error(message: 'Failed to create rule', payload: { errors: rule.errors.full_messages }, http_status: :unprocessable_entity)
      end
    end
  end
end
