# frozen_string_literal: true

require_dependency 'vulnerabilities/base_service'

module Vulnerabilities
  class RevertToDetectedService < BaseService
    REVERT_PARAMS = { resolved_by: nil, resolved_at: nil, dismissed_by: nil, dismissed_at: nil, confirmed_by: nil, confirmed_at: nil }.freeze

    def execute
      raise Gitlab::Access::AccessDeniedError unless authorized?

      update_vulnerability_with(state: Vulnerability.states[:detected], **REVERT_PARAMS) do
        DestroyDismissalFeedbackService.new(@user, @vulnerability).execute
      end

      @vulnerability
    end
  end
end
