# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::IpRestrictionHelper do
  let(:group) { create(:group) }

  describe '#ip_restriction_feature_available' do
    subject { helper.ip_restriction_feature_available?(group) }

    context 'when group_ip_restriction feature is available' do
      before do
        stub_licensed_features(group_ip_restriction: true)
      end

      it { is_expected.to be_truthy }
    end

    context 'when group_ip_restriction feature is disabled' do
      before do
        stub_licensed_features(group_ip_restriction: false)
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
