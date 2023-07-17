# frozen_string_literal: true

module PackageMetadata
  class StopSignal
    def initialize(lease, max_lease_length, max_duration)
      @lease = lease
      @max_lease_length = max_lease_length
      @max_duration = max_duration
    end

    def stop?
      max_duration < lease_time_elapsed
    end

    private

    attr_reader :lease, :max_duration, :max_lease_length

    def lease_time_elapsed
      max_lease_length - (lease.ttl || 0)
    end
  end
end
