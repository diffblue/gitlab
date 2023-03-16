# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Licenses::ResetSubmitLicenseUsageDataBannerWorker, type: :worker, feature_category: :sm_provisioning do
  describe '#perform' do
    subject(:reset_license_usage_data_exported) { described_class.new.perform }

    before do
      allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(false)
    end

    context 'when current license is nil' do
      before do
        License.current.destroy!
      end

      it 'does not reset the submit license usage data' do
        expect(Gitlab::Licenses::SubmitLicenseUsageDataBanner).not_to receive(:new)

        reset_license_usage_data_exported
      end
    end

    it 'resets the submit license usage data' do
      create_current_license({ cloud_licensing_enabled: true, offline_cloud_licensing_enabled: true })

      expect_next_instance_of(Gitlab::Licenses::SubmitLicenseUsageDataBanner) do |banner|
        expect(banner).to receive(:reset).and_call_original
      end

      reset_license_usage_data_exported
    end
  end
end
