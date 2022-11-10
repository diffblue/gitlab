# frozen_string_literal: true

module Gitlab
  module Elastic
    # Efficient cache for checking if Elasticsearch integration is enabled for
    # a resource. This presents a similar API to Rails cache but only accepts
    # booleans as values and sets cache expiry only on the initial access of
    # the overall resource cache. As such the cache will expire roughly daily
    # to ensure we don't grow unbounded in size with cached values for records
    # that are not recently accessed.
    #
    # Under the hood this is implemented using a Redis Hash and deleting is
    # just a `DEL` of the entire Hash. This kind of cache is preferred to the
    # normal Rails cache implemented as normal Redis key/value because we need
    # to invalidate the entire cache when we do invalidation which is too
    # inefficient without a hash.
    class ElasticsearchEnabledCache
      TTL_UNSET = -1
      EXPIRES_IN = 1.day

      class << self
        # Just like Rails::Cache.fetch but you provide the type of resource as well
        # as the key for the specific record.
        #
        # @param type [Symbol] the type of resource, `:project` or `:namespace`
        # @param record_id [Integer] the id of the record
        # @return [true, false]
        def fetch(type, record_id, &blk)
          with_redis do |redis|
            redis_key = redis_key(type)
            cached_result = redis.hget(redis_key, record_id)

            break Gitlab::Redis::Boolean.decode(cached_result) unless cached_result.nil?

            value = yield
            redis.hset(redis_key, record_id, Gitlab::Redis::Boolean.encode(value))

            # This does have a race condition where we may end up setting the
            # expire twice in short succession. This is not really a problem
            # since it will still expire after roughly the same amount of time.
            if redis.ttl(redis_key) == TTL_UNSET
              # Set an expiry only the first time we create the hash. If we
              # updated expiry every time then it may grow forever and never
              # expire. It's best to allow it to expire roughly daily to ensure
              # it doesn't get too large.
              redis.expire(redis_key, EXPIRES_IN)
            end

            value
          end
        end

        # Deletes the entire cache for this type. All keys in the cache will
        # be removed.
        #
        # @param type [Symbol] the type of resource, `:project` or `:namespace`
        def delete(type)
          with_redis { |redis| redis.unlink(redis_key(type)) }
        end

        # Deletes the specific record for this type. Only one key in the cache will
        # be removed.
        #
        # @param type [Symbol] the type of resource, `:project` or `:namespace`
        # @param record_id [Integer] the id of the record
        def delete_record(type, record_id)
          with_redis { |redis| redis.hdel(redis_key(type), record_id) }
        end

        private

        def redis_key(type)
          "elasticsearch_enabled_cache:#{type}"
        end

        def with_redis(&block)
          Gitlab::Redis::Cache.with(&block) # rubocop:disable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
