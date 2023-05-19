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

      def initialize(user)
        @user = user
      end

      def add(payload)
        return unless Feature.enabled?(:ai_redis_cache, user)

        data = {
          request_id: payload[:request_id],
          timestamp: Time.now.to_i
        }
        data[:response_body] = payload[:response_body][0, MAX_TEXT_LIMIT] if payload[:response_body]
        data[:error] = payload[:errors].join(". ") if payload[:errors]

        cache_data(data)
      end

      def get(request_id)
        all.find { |data| data['request_id'] == request_id && data['response_body'].present? }
      end

      def all
        with_redis do |redis|
          redis.xrange(key).map { |_id, data| data }
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
    end
  end
end
