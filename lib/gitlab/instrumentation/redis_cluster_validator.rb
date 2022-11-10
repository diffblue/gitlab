# frozen_string_literal: true

require 'rails'
require 'redis'

module Gitlab
  module Instrumentation
    module RedisClusterValidator
      # Generate with:
      #
      # Gitlab::Redis::Cache
      #   .with { |redis| redis.call('COMMAND') }
      #   .select { |command| command[3] != 0 }
      #   .map { |command| [
      #                     command[0].upcase,
      #                     { first: command[3], last: command[4], step: command[5], multi: command[3] != command[4] }
      #                    ]
      #   }
      #   .sort_by(&:first)
      #   .to_h
      REDIS_COMMANDS = {
        "APPEND" => { first: 1, last: 1, step: 1, multi: false },
        "BITCOUNT" => { first: 1, last: 1, step: 1, multi: false },
        "BITFIELD" => { first: 1, last: 1, step: 1, multi: false },
        "BITFIELD_RO" => { first: 1, last: 1, step: 1, multi: false },
        "BITOP" => { first: 2, last: -1, step: 1, multi: true },
        "BITPOS" => { first: 1, last: 1, step: 1, multi: false },
        "BLMOVE" => { first: 1, last: 2, step: 1, multi: true },
        "BLPOP" => { first: 1, last: -2, step: 1, multi: true },
        "BRPOP" => { first: 1, last: -2, step: 1, multi: true },
        "BRPOPLPUSH" => { first: 1, last: 2, step: 1, multi: true },
        "BZPOPMAX" => { first: 1, last: -2, step: 1, multi: true },
        "BZPOPMIN" => { first: 1, last: -2, step: 1, multi: true },
        "COPY" => { first: 1, last: 2, step: 1, multi: true },
        "DECR" => { first: 1, last: 1, step: 1, multi: false },
        "DECRBY" => { first: 1, last: 1, step: 1, multi: false },
        "DEL" => { first: 1, last: -1, step: 1, multi: true },
        "DUMP" => { first: 1, last: 1, step: 1, multi: false },
        "EXISTS" => { first: 1, last: -1, step: 1, multi: true },
        "EXPIRE" => { first: 1, last: 1, step: 1, multi: false },
        "EXPIREAT" => { first: 1, last: 1, step: 1, multi: false },
        "GEOADD" => { first: 1, last: 1, step: 1, multi: false },
        "GEODIST" => { first: 1, last: 1, step: 1, multi: false },
        "GEOHASH" => { first: 1, last: 1, step: 1, multi: false },
        "GEOPOS" => { first: 1, last: 1, step: 1, multi: false },
        "GEORADIUS" => { first: 1, last: 1, step: 1, multi: false },
        "GEORADIUSBYMEMBER" => { first: 1, last: 1, step: 1, multi: false },
        "GEORADIUSBYMEMBER_RO" => { first: 1, last: 1, step: 1, multi: false },
        "GEORADIUS_RO" => { first: 1, last: 1, step: 1, multi: false },
        "GEOSEARCH" => { first: 1, last: 1, step: 1, multi: false },
        "GEOSEARCHSTORE" => { first: 1, last: 2, step: 1, multi: true },
        "GET" => { first: 1, last: 1, step: 1, multi: false },
        "GETBIT" => { first: 1, last: 1, step: 1, multi: false },
        "GETDEL" => { first: 1, last: 1, step: 1, multi: false },
        "GETEX" => { first: 1, last: 1, step: 1, multi: false },
        "GETRANGE" => { first: 1, last: 1, step: 1, multi: false },
        "GETSET" => { first: 1, last: 1, step: 1, multi: false },
        "HDEL" => { first: 1, last: 1, step: 1, multi: false },
        "HEXISTS" => { first: 1, last: 1, step: 1, multi: false },
        "HGET" => { first: 1, last: 1, step: 1, multi: false },
        "HGETALL" => { first: 1, last: 1, step: 1, multi: false },
        "HINCRBY" => { first: 1, last: 1, step: 1, multi: false },
        "HINCRBYFLOAT" => { first: 1, last: 1, step: 1, multi: false },
        "HKEYS" => { first: 1, last: 1, step: 1, multi: false },
        "HLEN" => { first: 1, last: 1, step: 1, multi: false },
        "HMGET" => { first: 1, last: 1, step: 1, multi: false },
        "HMSET" => { first: 1, last: 1, step: 1, multi: false },
        "HRANDFIELD" => { first: 1, last: 1, step: 1, multi: false },
        "HSCAN" => { first: 1, last: 1, step: 1, multi: false },
        "HSET" => { first: 1, last: 1, step: 1, multi: false },
        "HSETNX" => { first: 1, last: 1, step: 1, multi: false },
        "HSTRLEN" => { first: 1, last: 1, step: 1, multi: false },
        "HVALS" => { first: 1, last: 1, step: 1, multi: false },
        "INCR" => { first: 1, last: 1, step: 1, multi: false },
        "INCRBY" => { first: 1, last: 1, step: 1, multi: false },
        "INCRBYFLOAT" => { first: 1, last: 1, step: 1, multi: false },
        "LINDEX" => { first: 1, last: 1, step: 1, multi: false },
        "LINSERT" => { first: 1, last: 1, step: 1, multi: false },
        "LLEN" => { first: 1, last: 1, step: 1, multi: false },
        "LMOVE" => { first: 1, last: 2, step: 1, multi: true },
        "LPOP" => { first: 1, last: 1, step: 1, multi: false },
        "LPOS" => { first: 1, last: 1, step: 1, multi: false },
        "LPUSH" => { first: 1, last: 1, step: 1, multi: false },
        "LPUSHX" => { first: 1, last: 1, step: 1, multi: false },
        "LRANGE" => { first: 1, last: 1, step: 1, multi: false },
        "LREM" => { first: 1, last: 1, step: 1, multi: false },
        "LSET" => { first: 1, last: 1, step: 1, multi: false },
        "LTRIM" => { first: 1, last: 1, step: 1, multi: false },
        "MGET" => { first: 1, last: -1, step: 1, multi: true },
        "MIGRATE" => { first: 3, last: 3, step: 1, multi: false },
        "MOVE" => { first: 1, last: 1, step: 1, multi: false },
        "MSET" => { first: 1, last: -1, step: 2, multi: true },
        "MSETNX" => { first: 1, last: -1, step: 2, multi: true },
        "OBJECT" => { first: 2, last: 2, step: 1, multi: false },
        "PERSIST" => { first: 1, last: 1, step: 1, multi: false },
        "PEXPIRE" => { first: 1, last: 1, step: 1, multi: false },
        "PEXPIREAT" => { first: 1, last: 1, step: 1, multi: false },
        "PFADD" => { first: 1, last: 1, step: 1, multi: false },
        "PFCOUNT" => { first: 1, last: -1, step: 1, multi: true },
        "PFDEBUG" => { first: 2, last: 2, step: 1, multi: false },
        "PFMERGE" => { first: 1, last: -1, step: 1, multi: true },
        "PSETEX" => { first: 1, last: 1, step: 1, multi: false },
        "PTTL" => { first: 1, last: 1, step: 1, multi: false },
        "RENAME" => { first: 1, last: 2, step: 1, multi: true },
        "RENAMENX" => { first: 1, last: 2, step: 1, multi: true },
        "RESTORE" => { first: 1, last: 1, step: 1, multi: false },
        "RESTORE-ASKING" => { first: 1, last: 1, step: 1, multi: false },
        "RPOP" => { first: 1, last: 1, step: 1, multi: false },
        "RPOPLPUSH" => { first: 1, last: 2, step: 1, multi: true },
        "RPUSH" => { first: 1, last: 1, step: 1, multi: false },
        "RPUSHX" => { first: 1, last: 1, step: 1, multi: false },
        "SADD" => { first: 1, last: 1, step: 1, multi: false },
        "SCARD" => { first: 1, last: 1, step: 1, multi: false },
        "SDIFF" => { first: 1, last: -1, step: 1, multi: true },
        "SDIFFSTORE" => { first: 1, last: -1, step: 1, multi: true },
        "SET" => { first: 1, last: 1, step: 1, multi: false },
        "SETBIT" => { first: 1, last: 1, step: 1, multi: false },
        "SETEX" => { first: 1, last: 1, step: 1, multi: false },
        "SETNX" => { first: 1, last: 1, step: 1, multi: false },
        "SETRANGE" => { first: 1, last: 1, step: 1, multi: false },
        "SINTER" => { first: 1, last: -1, step: 1, multi: true },
        "SINTERSTORE" => { first: 1, last: -1, step: 1, multi: true },
        "SISMEMBER" => { first: 1, last: 1, step: 1, multi: false },
        "SMEMBERS" => { first: 1, last: 1, step: 1, multi: false },
        "SMISMEMBER" => { first: 1, last: 1, step: 1, multi: false },
        "SMOVE" => { first: 1, last: 2, step: 1, multi: true },
        "SORT" => { first: 1, last: 1, step: 1, multi: false },
        "SPOP" => { first: 1, last: 1, step: 1, multi: false },
        "SRANDMEMBER" => { first: 1, last: 1, step: 1, multi: false },
        "SREM" => { first: 1, last: 1, step: 1, multi: false },
        "SSCAN" => { first: 1, last: 1, step: 1, multi: false },
        "STRLEN" => { first: 1, last: 1, step: 1, multi: false },
        "SUBSTR" => { first: 1, last: 1, step: 1, multi: false },
        "SUNION" => { first: 1, last: -1, step: 1, multi: true },
        "SUNIONSTORE" => { first: 1, last: -1, step: 1, multi: true },
        "TOUCH" => { first: 1, last: -1, step: 1, multi: true },
        "TTL" => { first: 1, last: 1, step: 1, multi: false },
        "TYPE" => { first: 1, last: 1, step: 1, multi: false },
        "UNLINK" => { first: 1, last: -1, step: 1, multi: true },
        "WATCH" => { first: 1, last: -1, step: 1, multi: true },
        "XACK" => { first: 1, last: 1, step: 1, multi: false },
        "XADD" => { first: 1, last: 1, step: 1, multi: false },
        "XAUTOCLAIM" => { first: 1, last: 1, step: 1, multi: false },
        "XCLAIM" => { first: 1, last: 1, step: 1, multi: false },
        "XDEL" => { first: 1, last: 1, step: 1, multi: false },
        "XGROUP" => { first: 2, last: 2, step: 1, multi: false },
        "XINFO" => { first: 2, last: 2, step: 1, multi: false },
        "XLEN" => { first: 1, last: 1, step: 1, multi: false },
        "XPENDING" => { first: 1, last: 1, step: 1, multi: false },
        "XRANGE" => { first: 1, last: 1, step: 1, multi: false },
        "XREVRANGE" => { first: 1, last: 1, step: 1, multi: false },
        "XSETID" => { first: 1, last: 1, step: 1, multi: false },
        "XTRIM" => { first: 1, last: 1, step: 1, multi: false },
        "ZADD" => { first: 1, last: 1, step: 1, multi: false },
        "ZCARD" => { first: 1, last: 1, step: 1, multi: false },
        "ZCOUNT" => { first: 1, last: 1, step: 1, multi: false },
        "ZDIFFSTORE" => { first: 1, last: 1, step: 1, multi: false },
        "ZINCRBY" => { first: 1, last: 1, step: 1, multi: false },
        "ZINTERSTORE" => { first: 1, last: 1, step: 1, multi: false },
        "ZLEXCOUNT" => { first: 1, last: 1, step: 1, multi: false },
        "ZMSCORE" => { first: 1, last: 1, step: 1, multi: false },
        "ZPOPMAX" => { first: 1, last: 1, step: 1, multi: false },
        "ZPOPMIN" => { first: 1, last: 1, step: 1, multi: false },
        "ZRANDMEMBER" => { first: 1, last: 1, step: 1, multi: false },
        "ZRANGE" => { first: 1, last: 1, step: 1, multi: false },
        "ZRANGEBYLEX" => { first: 1, last: 1, step: 1, multi: false },
        "ZRANGEBYSCORE" => { first: 1, last: 1, step: 1, multi: false },
        "ZRANGESTORE" => { first: 1, last: 2, step: 1, multi: true },
        "ZRANK" => { first: 1, last: 1, step: 1, multi: false },
        "ZREM" => { first: 1, last: 1, step: 1, multi: false },
        "ZREMRANGEBYLEX" => { first: 1, last: 1, step: 1, multi: false },
        "ZREMRANGEBYRANK" => { first: 1, last: 1, step: 1, multi: false },
        "ZREMRANGEBYSCORE" => { first: 1, last: 1, step: 1, multi: false },
        "ZREVRANGE" => { first: 1, last: 1, step: 1, multi: false },
        "ZREVRANGEBYLEX" => { first: 1, last: 1, step: 1, multi: false },
        "ZREVRANGEBYSCORE" => { first: 1, last: 1, step: 1, multi: false },
        "ZREVRANK" => { first: 1, last: 1, step: 1, multi: false },
        "ZSCAN" => { first: 1, last: 1, step: 1, multi: false },
        "ZSCORE" => { first: 1, last: 1, step: 1, multi: false },
        "ZUNIONSTORE" => { first: 1, last: 1, step: 1, multi: false }
      }.freeze

      CrossSlotError = Class.new(StandardError)

      class << self
        def validate!(commands)
          return unless Rails.env.development? || Rails.env.test?
          return if allow_cross_slot_commands?
          return if commands.empty?

          command_name = commands.size > 1 ? "PIPELINE/MULTI" : commands.first.first.to_s.upcase
          argument_positions = REDIS_COMMANDS[command_name]

          # early exit for single-command (non-pipelined) if it is a single-key-command
          return if commands.size == 1 && argument_positions && !argument_positions[:multi]

          key_slots = commands.map { |command| key_slots(command) }.flatten
          if key_slots.uniq.many? # rubocop: disable CodeReuse/ActiveRecord
            raise CrossSlotError, "Redis command #{command_name} arguments hash to different slots. See https://docs.gitlab.com/ee/development/redis.html#multi-key-commands"
          end
        end

        # Keep track of the call stack to allow nested calls to work.
        def allow_cross_slot_commands
          Thread.current[:allow_cross_slot_commands] ||= 0
          Thread.current[:allow_cross_slot_commands] += 1

          yield
        ensure
          Thread.current[:allow_cross_slot_commands] -= 1
        end

        private

        def key_slots(command)
          argument_positions = REDIS_COMMANDS[command.first.to_s.upcase]

          return [] unless argument_positions

          arguments = command.flatten[argument_positions[:first]..argument_positions[:last]]
          arguments.each_slice(argument_positions[:step]).map do |args|
            key_slot(args.first)
          end
        end

        def allow_cross_slot_commands?
          Thread.current[:allow_cross_slot_commands].to_i > 0
        end

        def key_slot(key)
          ::Redis::Cluster::KeySlotConverter.convert(extract_hash_tag(key))
        end

        # This is almost identical to Redis::Cluster::Command#extract_hash_tag,
        # except that it returns the original string if no hash tag is found.
        #
        def extract_hash_tag(key)
          s = key.index('{')

          return key unless s

          e = key.index('}', s + 1)

          return key unless e

          key[s + 1..e - 1]
        end
      end
    end
  end
end
