# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ExclusiveLease, :clean_gitlab_redis_shared_state do
  let(:unique_key) { SecureRandom.hex(10) }

  before do
    stub_feature_flags(
      use_cluster_shared_state_for_exclusive_lease: false,
      enable_exclusive_lease_double_lock_rw: false
    )
  end

  describe '#try_obtain_with_ttl' do
    it 'cannot obtain twice before the lease has expired' do
      lease = described_class.new(unique_key, timeout: 3600)

      ttl_lease = lease.try_obtain_with_ttl

      expect(ttl_lease[:uuid]).to be_present
      expect(ttl_lease[:ttl]).to eq(0)

      second_ttl_lease = lease.try_obtain_with_ttl

      expect(second_ttl_lease[:uuid]).to be false
      expect(second_ttl_lease[:ttl]).to be > 0
    end

    it 'can obtain after the lease has expired' do
      timeout = 1
      lease = described_class.new(unique_key, timeout: 1)

      sleep(2 * timeout) # lease should have expired now

      ttl_lease = lease.try_obtain_with_ttl

      expect(ttl_lease[:uuid]).to be_present
      expect(ttl_lease[:ttl]).to eq(0)
    end
  end

  describe '#same_uuid?' do
    it 'returns true for an existing lease' do
      lease = described_class.new(unique_key, timeout: 3600)
      lease.try_obtain

      expect(lease.same_uuid?).to eq(true)
    end

    it 'returns false for a lease that does not exist' do
      described_class.new(unique_key, timeout: 3600).try_obtain

      lease = described_class.new(unique_key, timeout: 3600)

      expect(lease.same_uuid?).to eq(false)
    end
  end
end
