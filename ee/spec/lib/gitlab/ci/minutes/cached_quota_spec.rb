# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Minutes::CachedQuota do
  let_it_be(:namespace) { create(:namespace, shared_runners_minutes_limit: 100) }

  let(:cached_quota) { described_class.new(namespace) }

  describe '#track_consumption', :redis do
    subject { cached_quota.track_consumption(consumption) }

    let(:consumption) { 10 }

    context 'when the cache is cold' do
      it 'stores the remaining minutes in the cache and decrements them from there' do
        freeze_time do
          expect(cached_quota).to receive(:uncached_current_balance).and_call_original

          expect(subject).to eq(90.0)

          ::Gitlab::Redis::SharedState.with do |redis|
            expect(redis.ttl(cached_quota.cache_key)).to eq(described_class::TTL_REMAINING_MINUTES)
          end
        end
      end
    end

    context 'when the cache is warm' do
      before do
        ::Gitlab::Redis::SharedState.with do |redis|
          redis.set(cached_quota.cache_key, 80.0, ex: 20)
        end
      end

      it 'only decrements the consumption' do
        freeze_time do
          expect(cached_quota).not_to receive(:uncached_current_balance)

          expect(subject).to eq(70.0)

          ::Gitlab::Redis::SharedState.with do |redis|
            expect(redis.ttl(cached_quota.cache_key)).to eq(described_class::TTL_REMAINING_MINUTES)
          end
        end
      end
    end
  end

  describe '#expire!' do
    subject { cached_quota.expire! }

    before do
      ::Gitlab::Redis::SharedState.with do |redis|
        redis.set(cached_quota.cache_key, 80.0, ex: 20)
      end
    end

    it 'expires the key' do
      subject

      ::Gitlab::Redis::SharedState.with do |redis|
        expect(redis.exists?(cached_quota.cache_key)).to eq(false)
      end
    end
  end
end
