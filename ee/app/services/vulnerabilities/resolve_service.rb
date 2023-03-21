# frozen_string_literal: true

require_dependency 'vulnerabilities/base_state_transition_service'

module Vulnerabilities
  class ResolveService < BaseStateTransitionService
    private

    def update_vulnerability!
      update_vulnerability_with(state: :resolved, resolved_by: @user, resolved_at: Time.current) do
        DestroyDismissalFeedbackService.new(@user, @vulnerability).execute # we can remove this as part of https://gitlab.com/gitlab-org/gitlab/-/issues/324899
      end
    end

    def to_state
      :resolved
    end

    def can_transition?
      !@vulnerability.resolved?
    end
  end
end
