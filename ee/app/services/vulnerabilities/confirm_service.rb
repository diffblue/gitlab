# frozen_string_literal: true

require_dependency 'vulnerabilities/base_service'

module Vulnerabilities
  class ConfirmService < BaseService
    def execute
      raise Gitlab::Access::AccessDeniedError unless authorized?

      unless @vulnerability.confirmed?
        ApplicationRecord.transaction do
          Vulnerabilities::StateTransition.create!(
            vulnerability: @vulnerability,
            from_state: @vulnerability.state,
            to_state: :confirmed
          )

          update_vulnerability_with(state: :confirmed, confirmed_by: @user,
                                    confirmed_at: Time.current) do
            DestroyDismissalFeedbackService.new(@user, @vulnerability).execute # we can remove this as part of https://gitlab.com/gitlab-org/gitlab/-/issues/324899
          end
        end
      end

      @vulnerability
    end
  end
end
