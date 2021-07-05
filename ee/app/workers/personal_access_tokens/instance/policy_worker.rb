# frozen_string_literal: true

module PersonalAccessTokens
  module Instance
    class PolicyWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3

      queue_namespace :personal_access_tokens
      feature_category :authentication_and_authorization

      def perform
        expiration_date = ::Gitlab::CurrentSettings.max_personal_access_token_lifetime_from_now

        return unless expiration_date

        # for users who are not managed by any group
        User.not_managed.with_invalid_expires_at_tokens(expiration_date).find_each do |user|
          PersonalAccessTokens::RevokeInvalidTokens.new(user, expiration_date).execute
        end

        # for users who are managed by groups, but these groups follow the instance level expiry policy
        ::Group.with_managed_accounts_enabled.with_no_pat_expiry_policy.find_each do |group|
          User.managed_by(group).with_invalid_expires_at_tokens(expiration_date).find_each do |user|
            PersonalAccessTokens::RevokeInvalidTokens.new(user, expiration_date).execute
          end
        end
      end
    end
  end
end
