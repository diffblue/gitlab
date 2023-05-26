# frozen_string_literal: true

module PersonalAccessTokens
  class RevokeInvalidTokens
    def initialize(user, expiration_date)
      @user = user
      @expiration_date = expiration_date
    end

    def execute
      # TODO: Change to `project.feature_available?` https://gitlab.com/gitlab-org/gitlab/-/issues/323908
      return unless ::License.feature_available?(:personal_access_token_expiration_policy)
      return unless expiration_date && user_affected?

      notify_user

      revoke_tokens!
    end

    private

    attr_reader :user, :expiration_date

    def user_affected?
      user && affected_tokens.any?
    end

    def notify_user
      return unless user.can?(:receive_notifications)

      mailer.policy_revoked_personal_access_tokens_email(user, affected_tokens.pluck_names).deliver_later
    end

    def mailer
      Notify
    end

    def affected_tokens
      @affected_tokens ||= user.personal_access_tokens.with_invalid_expires_at(expiration_date)
    end

    def revoke_tokens!
      personal_access_tokens.with_expires_at_after(expiration_date).update_all(revoked: true)
    end

    def personal_access_tokens
      @personal_access_tokens ||= user.personal_access_tokens
    end
  end
end
