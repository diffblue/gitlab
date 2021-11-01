# frozen_string_literal: true

module Gitlab
  module Redis
    class MultiStore
      attr_reader :primary_store, :secondary_store

      READ_COMMANDS = %i(
        get
        mget
        smembers
      ).freeze

      WRITE_COMMANDS = %i(
        setnx
        setex
        sadd
        srem
        del
        pipelined
        flushdb
      ).freeze

      def initialize(primary_store_options, secondary_store_options)
        @primary_store = ::Redis::Store.new(primary_store_options)
        @secondary_store = ::Redis::Store.new(secondary_store_options)
      end

      # This is needed because of Redis::Rack::Connection is requiring Redis::Store
      # https://github.com/redis-store/redis-rack/blob/a833086ba494083b6a384a1a4e58b36573a9165d/lib/redis/rack/connection.rb#L15
      # Done similarly in https://github.com/lsegal/yard/blob/main/lib/yard/templates/template.rb#L122
      def is_a?(klass)
        return true if klass == ::Redis::Store

        super(klass)
      end

      # TODO: Add Feature flags, by default read only from the secondary store,
      # by enabling the FF, read from the primary, and fallback to read from the secondary.
      READ_COMMANDS.each do |name|
        define_method(name) do |*args, **kwargs, &block|
          if @instance
            send_command(@instance, name, *args, **kwargs, &block)
          else
            value = send_command(primary_store, name, *args, **kwargs, &block)
            # TODO: Add logger to detect for which key we fallback to shared_steate_store
            value ||= send_command(secondary_store, name, *args, **kwargs, &block)

            value
          end
        end
      end

      # TODO: Add proper error handling if primary store fails, ensuring that we execute at least on secondary store
      # TODO: Add Feature flags, by default write only on the secondary store (SharedState), by enabling the FF, write to the primary as well.
      WRITE_COMMANDS.each do |name|
        define_method(name) do |*args, **kwargs, &block|
          if @instance
            send_command(@instance, name, *args, **kwargs, &block)
          else
            send_command(primary_store, name, *args, **kwargs, &block)
            send_command(secondary_store, name, *args, **kwargs, &block)
          end
        end
      end

      # TEST: try to avoid Deprecation Toolkit issues
      # See the pipelines of the POC for the example
      # We call set there https://github.com/redis-store/redis-rack/blob/v2.1.3/lib/rack/session/redis.rb#L49
      # With the meta-definition like there, we have hash <-> kwargs Ruby 2.7 issues as the downstream is defined like:
      # https://github.com/redis/redis-rb/blob/master/lib/redis.rb#L846
      def set(...)
        if @instance
          send_command(@instance, :set, ...)
        else
          send_command(primary_store, :set, ...)
          send_command(secondary_store, :set, ...)
        end
      end

      private

      def send_command(redis_instance, name, *args, **kwargs, &block)
        if block_given?
          redis_instance.send(name, *args, **kwargs) do |*args| # rubocop:disable GitlabSecurity/PublicSend
            with_instance(redis_instance, *args, &block)
          end
        else
          redis_instance.send(name, *args, **kwargs) # rubocop:disable GitlabSecurity/PublicSend
        end
      end

      def with_instance(instance, *args)
        @instance = instance
        yield(*args)
      ensure
        @instance = nil
      end

      def method_missing(...)
        # TODO: Add logger here to log for which key and command we did fallback to the shared_state_store
        secondary_store.send(...) # rubocop:disable GitlabSecurity/PublicSend
      end

      def respond_to_missing?(method_name, include_private = false)
        true
      end
    end
  end
end
