# frozen_string_literal: true

require_dependency 'vulnerabilities/base_service'

module Vulnerabilities
  class ConfirmService < BaseService
    def execute
      raise Gitlab::Access::AccessDeniedError unless authorized?

      if Feature.enabled?(:deprecate_vulnerabilities_feedback, @vulnerability.project)
        update_vulnerability_with(state: Vulnerability.states[:confirmed], confirmed_by: @user,
                                  confirmed_at: Time.current)
      else
        update_vulnerability_with(state: Vulnerability.states[:confirmed], confirmed_by: @user,
                                  confirmed_at: Time.current) do
          DestroyDismissalFeedbackService.new(@user, @vulnerability).execute
        end
      end

      @vulnerability
    end
  end
end
