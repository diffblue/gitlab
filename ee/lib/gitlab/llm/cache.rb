# frozen_string_literal: true

module Gitlab
  module Llm
    class Cache
      EXPIRE_TIME =  30.minutes
      MAX_MESSAGES = 20
      # AI provider-specific limits are applied to requests/responses. To not
      # rely only on third-party limits and assure that cache usage can't be
      # exhausted by users by sending huge texts/responses, we apply also
      # safeguard limit on maximum size of cached response. 1 token ~= 4 chars
      # in English, limit is typically ~4100 -> so 20000 char limit should be
      # sufficient.
      MAX_TEXT_LIMIT = 20_000

      ROLE_USER = 'user'
      ROLE_ASSISTANT = 'assistant'
      ALLOWED_ROLES = [ROLE_USER, ROLE_ASSISTANT].freeze

      def initialize(user)
        @user = user
      end

      def add(payload)
        return unless Feature.enabled?(:ai_redis_cache, user)

        raise ArgumentError, "Invalid role '#{payload[:role]}'" unless ALLOWED_ROLES.include?(payload[:role])

        data = {
          id: SecureRandom.uuid,
          request_id: payload[:request_id],
          timestamp: Time.current.to_s,
          role: payload[:role]
        }
        data[:content] = payload[:content][0, MAX_TEXT_LIMIT] if payload[:content]
        data[:error] = payload[:errors].join(". ") if payload[:errors].present?

        cache_data(data)
      end

      def find_all(filters = {})
        with_redis do |redis|
          redis.xrange(key).filter_map do |_id, data|
            CachedMessage.new(data) if matches_filters?(data, filters)
          end
        end
      end

      private

      attr_reader :user

      def cache_data(data)
        with_redis do |redis|
          redis.xadd(key, data, maxlen: MAX_MESSAGES)
          redis.expire(key, EXPIRE_TIME)
        end
      end

      def key
        "ai_chat:#{user.id}"
      end

      def with_redis(&block)
        Gitlab::Redis::Chat.with(&block) # rubocop: disable CodeReuse/ActiveRecord
      end

      def matches_filters?(data, filters)
        return false if filters[:roles]&.exclude?(data['role'])
        return false if filters[:request_ids]&.exclude?(data['request_id'])

        data
      end
    end
  end
end
