# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Smartcard::Session do
  describe '#active?' do
    let(:user) { create(:user) }

    subject { described_class.new.active?(user) }

    context 'with a smartcard session', :clean_gitlab_redis_sessions do
      let(:session_id) { '42' }
      let(:stored_session) do
        { 'smartcard_signins' => { 'last_signin_at' => 5.minutes.ago } }
      end

      before do
        Gitlab::Redis::Sessions.with do |redis|
          redis.set("session:gitlab:#{session_id}", Marshal.dump(stored_session))
          redis.sadd("session:lookup:user:gitlab:#{user.id}", [session_id])
        end
      end

      it { is_expected.to be_truthy }
    end

    context 'without any session' do
      it { is_expected.to be_falsey }
    end
  end

  describe '#update_active' do
    let(:now) { Time.current }

    around do |example|
      Gitlab::Session.with_session({}) do
        example.run
      end
    end

    it 'stores the time of last sign-in' do
      subject.update_active(now)

      expect(Gitlab::Session.current[:smartcard_signins]).to eq({ 'last_signin_at' => now })
    end
  end
end
