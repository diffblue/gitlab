# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::CaptchaChallengeService, feature_category: :system_access do
  describe '#execute' do
    let_it_be_with_reload(:user) { create(:user) }

    let(:should_challenge?) { true }
    let(:result) { { result: should_challenge? } }

    subject { Users::CaptchaChallengeService.new(user).execute }

    context 'when feature flag arkose_labs_login_challenge is disabled' do
      let(:should_challenge?) { false }

      before do
        stub_feature_flags(arkose_labs_login_challenge: false)
      end

      it { is_expected.to eq(result) }
    end

    context 'when feature flag arkose_labs_login_challenge is enabled' do
      before do
        stub_feature_flags(arkose_labs_login_challenge: true)
      end

      context 'when the user does not exist' do
        subject { Users::CaptchaChallengeService.new(nil).execute }

        it { is_expected.to eq(result) }
      end

      context 'when the user has never logged in previously' do
        before do
          user.last_sign_in_at = nil
        end

        it { is_expected.to eq(result) }
      end

      context 'when the user has not logged in successfully in more than 3 months' do
        before do
          user.last_sign_in_at = Date.today - 4.months
        end

        it { is_expected.to eq(result) }
      end

      context 'when the user has 3 failed login attempts' do
        before do
          user.last_sign_in_at = Date.today - 2.months
          user.failed_attempts = 3
        end

        it { is_expected.to eq(result) }
      end

      context 'when the user has logged in previously in less than 3 months' do
        before do
          user.last_sign_in_at = Date.today - 2.months
        end

        let(:should_challenge?) { false }

        it { is_expected.to eq(result) }
      end
    end
  end
end
