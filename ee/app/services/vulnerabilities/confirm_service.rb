# frozen_string_literal: true

require_dependency 'vulnerabilities/base_state_transition_service'

module Vulnerabilities
  class ConfirmService < BaseStateTransitionService
    private

    def update_vulnerability!
      update_vulnerability_with(state: :confirmed, confirmed_by: @user,
                                confirmed_at: Time.current) do
        DestroyDismissalFeedbackService.new(@user, @vulnerability).execute # we can remove this as part of https://gitlab.com/gitlab-org/gitlab/-/issues/324899
      end
    end

    def to_state
      :confirmed
    end

    def can_transition?
      !@vulnerability.confirmed?
    end
  end
end
