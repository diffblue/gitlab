# frozen_string_literal: true

require_dependency 'vulnerabilities/base_state_transition_service'

module Vulnerabilities
  class RevertToDetectedService < BaseStateTransitionService
    REVERT_PARAMS = { resolved_by: nil, resolved_at: nil, dismissed_by: nil, dismissed_at: nil, confirmed_by: nil, confirmed_at: nil }.freeze

    private

    def update_vulnerability!
      update_vulnerability_with(state: :detected, **REVERT_PARAMS) do
        DestroyDismissalFeedbackService.new(@user, @vulnerability).execute # we can remove this as part of https://gitlab.com/gitlab-org/gitlab/-/issues/324899
      end
    end

    def to_state
      :detected
    end

    def can_transition?
      !@vulnerability.detected?
    end
  end
end
