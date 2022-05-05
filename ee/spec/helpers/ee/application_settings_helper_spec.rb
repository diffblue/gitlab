# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::ApplicationSettingsHelper do
  describe '.visible_attributes' do
    it 'contains personal access token parameters' do
      expect(visible_attributes).to include(*%i(max_personal_access_token_lifetime))
    end

    it 'contains slack app parameters' do
      params = %i(slack_app_enabled slack_app_id slack_app_secret slack_app_signing_secret slack_app_verification_token)

      expect(helper.visible_attributes).to include(*params)
    end
  end

  describe '.registration_features_can_be_prompted?' do
    subject { helper.registration_features_can_be_prompted? }

    context 'without a valid license' do
      before do
        allow(License).to receive(:current).and_return(nil)
      end

      context 'when service ping is enabled' do
        before do
          stub_application_setting(usage_ping_enabled: true)
        end

        it { is_expected.to be_falsey }
      end

      context 'when service ping is disabled' do
        before do
          stub_application_setting(usage_ping_enabled: false)
        end

        it { is_expected.to be_truthy }
      end
    end

    context 'with a license' do
      let(:license) { build(:license) }

      before do
        allow(License).to receive(:current).and_return(license)
      end

      it { is_expected.to be_falsey }

      context 'when service ping is disabled' do
        before do
          stub_application_setting(usage_ping_enabled: false)
        end

        it { is_expected.to be_falsey }
      end
    end
  end
end
