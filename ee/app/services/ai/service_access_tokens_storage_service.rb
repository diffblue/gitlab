# frozen_string_literal: true

module Ai
  class ServiceAccessTokensStorageService
    def initialize(token, expires_at, category)
      @token = token
      @expires_at = expires_at
      @category = category
    end

    def execute
      return false unless valid_category?

      if token && expires_at
        store_token
        cleanup_expired_tokens
      else
        cleanup_all_tokens
      end
    end

    private

    attr_reader :token, :expires_at, :category

    def store_token
      tokens_for_category.create!(token: token, expires_at: expires_at_time)
      log_event({ action: 'created', expires_at: expires_at_time })
    rescue StandardError => err
      Gitlab::ErrorTracking.track_exception(err)
    end

    def expires_at_time
      return if expires_at.nil?

      Time.at(expires_at, in: '+00:00')
    end

    def cleanup_expired_tokens
      tokens_for_category.expired.delete_all
      log_event({ action: 'cleanup_expired' })
    end

    def cleanup_all_tokens
      tokens_for_category.delete_all
      log_event({ action: 'cleanup_all' })
    end

    def tokens_for_category
      Ai::ServiceAccessToken.for_category(category)
    end

    def log_event(log_fields)
      Gitlab::AppLogger.info(
        message: 'service_access_tokens',
        service_token_category: category.to_s,
        **log_fields
      )
    end

    def valid_category?
      Ai::ServiceAccessToken.categories.key?(category.to_s)
    end
  end
end
