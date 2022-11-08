# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Otp::SessionEnforcer, :clean_gitlab_redis_sessions do
  let_it_be(:key) { create(:key) }

  describe '#update_session' do
    let(:redis) { double(:redis) }

    before do
      stub_licensed_features(git_two_factor_enforcement: true)
    end

    it 'registers a session in Redis' do
      expect(Gitlab::Redis::Sessions).to receive(:with).and_yield(redis)
      session_expiry_in_seconds = Gitlab::CurrentSettings.git_two_factor_session_expiry.minutes.to_i

      expect(redis).to(
        receive(:setex)
          .with("#{::Gitlab::Redis::Sessions::OTP_SESSIONS_NAMESPACE}:#{key.id}",
                session_expiry_in_seconds,
                true)
          .once)

      described_class.new(key).update_session
    end

    context 'when licensed feature is not available' do
      before do
        stub_licensed_features(git_two_factor_enforcement: false)
      end

      it 'does not register a session in Redis' do
        expect(redis).not_to receive(:setex)

        described_class.new(key).update_session
      end
    end
  end

  describe '#access_restricted?' do
    subject { described_class.new(key).access_restricted? }

    before do
      stub_licensed_features(git_two_factor_enforcement: true)
    end

    context 'with existing session' do
      before do
        Gitlab::Redis::Sessions.with do |redis|
          redis.set("#{::Gitlab::Redis::Sessions::OTP_SESSIONS_NAMESPACE}:#{key.id}", true)
        end
      end

      it { is_expected.to be_falsey }
    end

    context 'without an existing session' do
      it { is_expected.to be_truthy }
    end
  end
end
