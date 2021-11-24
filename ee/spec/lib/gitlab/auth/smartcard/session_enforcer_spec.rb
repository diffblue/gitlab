# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Smartcard::SessionEnforcer do
  describe '#update_session' do
    let(:session) { {} }

    around do |example|
      Gitlab::Session.with_session(session) do
        example.run
      end
    end

    it 'stores the time of last sign-in in session' do
      expect { subject.update_session }.to change { session[:smartcard_signins] }
      expect(session[:smartcard_signins]).to have_key('last_signin_at')
      expect(session[:smartcard_signins]['last_signin_at']).not_to be_nil
    end
  end

  describe '#access_restricted?' do
    let(:user) { create(:user) }

    subject { described_class.new.access_restricted?(user) }

    before do
      stub_licensed_features(smartcard_auth: true)
      stub_smartcard_setting(enabled: true, required_for_git_access: true)
    end

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

      it { is_expected.to be_falsey }
    end

    context 'without any session' do
      it { is_expected.to be_truthy }
    end

    context 'with the setting off' do
      before do
        stub_smartcard_setting(required_for_git_access: false)
      end

      it { is_expected.to be_falsey }
    end

    context 'with smartcard auth disabled' do
      before do
        stub_smartcard_setting(enabled: false)
      end

      it { is_expected.to be_falsey }
    end

    context 'without a license' do
      before do
        stub_licensed_features(smartcard_auth: false)
      end

      it { is_expected.to be_falsey }
    end
  end
end
