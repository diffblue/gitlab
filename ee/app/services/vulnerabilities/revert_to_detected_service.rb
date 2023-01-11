# frozen_string_literal: true

require_dependency 'vulnerabilities/base_service'

module Vulnerabilities
  class RevertToDetectedService < BaseService
    REVERT_PARAMS = { resolved_by: nil, resolved_at: nil, dismissed_by: nil, dismissed_at: nil, confirmed_by: nil, confirmed_at: nil }.freeze

    def execute
      raise Gitlab::Access::AccessDeniedError unless authorized?

      unless @vulnerability.detected?
        ApplicationRecord.transaction do
          Vulnerabilities::StateTransition.create!(
            vulnerability: @vulnerability,
            from_state: @vulnerability.state,
            to_state: :detected,
            author: @user
          )

          update_vulnerability_with(state: :detected, **REVERT_PARAMS) do
            DestroyDismissalFeedbackService.new(@user, @vulnerability).execute # we can remove this as part of https://gitlab.com/gitlab-org/gitlab/-/issues/324899
          end
        end
      end

      @vulnerability
    end
  end
end
