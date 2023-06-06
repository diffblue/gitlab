# frozen_string_literal: true

module Ai
  class JobFailureAnalysis
    def initialize(job)
      @job = job
    end

    def save_content(data)
      with_redis do |redis|
        redis.set(key, data, ex: 1.day)
      end
    end

    def content
      with_redis do |redis|
        redis.get(key)
      end
    end

    private

    def key
      [self.class.name, @job.id].join('/')
    end

    def with_redis(&block)
      Gitlab::Redis::Chat.with(&block) # rubocop: disable CodeReuse/ActiveRecord
    end
  end
end
