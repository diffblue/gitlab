# frozen_string_literal: true

module ExternalStatusChecks
  class RetryService < BaseService
    def execute(rule)
      return unauthorized_error_response unless current_user.can?(:retry_failed_status_checks, params[:merge_request])
      return not_failed_error_response unless rule.failed?(params[:merge_request])

      last_response = rule.response_for(params[:merge_request], params[:merge_request].diff_head_sha)

      if last_response.update(retried_at: Time.current)
        data = params[:merge_request].to_hook_data(current_user)
        rule.async_execute(data)
        ServiceResponse.success(payload: { rule: rule })
      else
        ServiceResponse.error(message: 'Failed to retry rule',
          payload: { errors: rule.errors.full_messages },
          reason: :unprocessable_entity)
      end
    end

    private

    def not_failed_error_response
      ServiceResponse.error(
        message: 'Failed to retry rule',
        payload: { errors: 'External status check must be failed' },
        reason: :unprocessable_entity
      )
    end

    def unauthorized_error_response
      ServiceResponse.error(
        message: 'Failed to retry rule',
        payload: { errors: 'Not allowed' },
        reason: :unauthorized
      )
    end
  end
end
