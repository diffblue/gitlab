# frozen_string_literal: true

module Gitlab
  module Redis
    class MultiStore
      class ReadFromPrimaryError < StandardError
        def message
          'Value not found on the redis primary store. Read from the redis secondary store successful.'
        end
      end
      class MultiReadError < StandardError
        def message
          'Value not found on both primary and secondary store.'
        end
      end
      class MethodMissingError < StandardError
        def message
          'Method missing. Falling back to execute method on the redis secondary store.'
        end
      end

      attr_reader :primary_store, :secondary_store

      FAILED_TO_READ_ERROR_MESSAGE = 'Failed to read from the redis primary_store.'
      FAILED_TO_WRITE_ERROR_MESSAGE = 'Failed to write to the redis primary_store.'

      READ_COMMANDS = %i(
        get
        mget
        smembers
        scard
      ).freeze

      WRITE_COMMANDS = %i(
        set
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

      READ_COMMANDS.each do |name|
        define_method(name) do |*args, &block|
          if multi_store_enabled?
            read_command(name, *args, &block)
          else
            secondary_store.send(name, *args, &block) # rubocop:disable GitlabSecurity/PublicSend
          end
        end
      end

      WRITE_COMMANDS.each do |name|
        define_method(name) do |*args, &block|
          if multi_store_enabled?
            write_command(name, *args, &block)
          else
            secondary_store.send(name, *args, &block) # rubocop:disable GitlabSecurity/PublicSend
          end
        end
      end

      def method_missing(command_name, *args, &block)
        if @instance
          send_command(@instance, command_name, *args, &block)
        else
          log_error(MethodMissingError.new, command_name)
          increment_method_missing_count(command_name)

          secondary_store.send(command_name, *args, &block) # rubocop:disable GitlabSecurity/PublicSend
        end
      end

      def respond_to_missing?(command_name, include_private = false)
        true
      end

      private

      def read_command(command_name, *args, &block)
        if @instance
          send_command(@instance, command_name, *args, &block)
        else
          read_one_with_fallback(command_name, *args, &block)
        end
      end

      def write_command(command_name, *args, &block)
        if @instance
          send_command(@instance, command_name, *args, &block)
        else
          write_both(command_name, *args, &block)
        end
      end

      def read_one_with_fallback(command_name, *args, &block)
        begin
          value = send_command(primary_store, command_name, *args, &block)
        rescue StandardError => e
          log_error(e, command_name,
            multi_store_error_message: FAILED_TO_READ_ERROR_MESSAGE)
        end

        value ||= fallback_read(command_name, *args, &block)

        value
      end

      def fallback_read(command_name, *args, &block)
        value = send_command(secondary_store, command_name, *args, &block)

        if value
          log_error(ReadFromPrimaryError.new, command_name)
          increment_read_fallback_count(command_name)
        else
          log_error(MultiReadError.new, command_name)
        end

        value
      end

      def write_both(command_name, *args, &block)
        begin
          send_command(primary_store, command_name, *args, &block)
        rescue StandardError => e
          log_error(e, command_name,
            multi_store_error_message: FAILED_TO_WRITE_ERROR_MESSAGE)
        end

        send_command(secondary_store, command_name, *args, &block)
      end

      def multi_store_enabled?
        Feature.enabled?(:use_multi_store, default_enabled: :yaml)
      end

      # rubocop:disable GitlabSecurity/PublicSend
      def send_command(redis_instance, command_name, *args, &block)
        if block_given?
          # Make sure that block is wrapped and executed only on the redis instance that is executing the block
          redis_instance.send(command_name, *args) do |*args|
            with_instance(redis_instance, *args, &block)
          end
        else
          redis_instance.send(command_name, *args)
        end
      end
      # rubocop:enable GitlabSecurity/PublicSend

      def with_instance(instance, *args)
        @instance = instance
        yield(*args)
      ensure
        @instance = nil
      end

      def increment_read_fallback_count(command_name)
        @read_fallback_counter ||= Gitlab::Metrics.counter(:gitlab_redis_multi_store_read_fallback_total, 'Client side Redis MultiStore reading fallback')
        @read_fallback_counter.increment(command: command_name)
      end

      def increment_method_missing_count(command_name)
        @method_missing_counter ||= Gitlab::Metrics.counter(:gitlab_redis_multi_store_method_missing_total, 'Client side Redis MultiStore method missing')
        @method_missing_counter.increment(command: command_name)
      end

      def log_error(exception, command_name, extra = {})
        Gitlab::ErrorTracking.log_exception(
          exception,
          command_name: command_name,
          extra: extra)
      end
    end
  end
end
