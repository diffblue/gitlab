# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RegistrationFeatures::PasswordComplexity, feature_category: :service_ping do
  describe '.feature_available?' do
    subject { described_class.feature_available? }

    context 'when password_complexity feature is available' do
      before do
        stub_licensed_features(password_complexity: true)
      end

      it { is_expected.to be_truthy }
    end

    context 'when password_complexity feature is disabled' do
      before do
        stub_licensed_features(password_complexity: false)
      end

      it { is_expected.to be_falsey }
    end

    context 'when usage ping is enabled' do
      before do
        stub_application_setting(usage_ping_enabled: true)
      end

      context 'when usage_ping_features is enabled' do
        before do
          stub_application_setting(usage_ping_features_enabled: true)
        end

        it { is_expected.to be_truthy }
      end

      context 'when usage_ping_features is disabled' do
        before do
          stub_application_setting(usage_ping_features_enabled: false)
        end

        it { is_expected.to be_falsey }
      end
    end

    context 'when usage ping is disabled' do
      before do
        stub_application_setting(usage_ping_enabled: false)
      end

      it { is_expected.to be_falsey }
    end
  end
end
