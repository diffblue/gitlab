# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RegistrationFeatures::MaintenanceMode, feature_category: :service_ping do
  describe '.feature_available?' do
    subject { described_class.feature_available? }

    context 'when geo feature is available' do
      before do
        stub_licensed_features(geo: true)
      end

      it { is_expected.to be_truthy }
    end

    context 'when geo feature is disabled' do
      before do
        stub_licensed_features(geo: false)
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
