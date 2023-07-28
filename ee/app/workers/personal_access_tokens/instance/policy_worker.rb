# frozen_string_literal: true

module PersonalAccessTokens
  module Instance
    class PolicyWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3

      queue_namespace :personal_access_tokens
      feature_category :system_access

      def perform
        expiration_date = ::Gitlab::CurrentSettings.max_personal_access_token_lifetime_from_now

        return unless expiration_date

        User.with_invalid_expires_at_tokens(expiration_date).find_each do |user|
          PersonalAccessTokens::RevokeInvalidTokens.new(user, expiration_date).execute
        end
      end
    end
  end
end
