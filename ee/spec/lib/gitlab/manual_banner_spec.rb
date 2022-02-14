# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ManualBanner do
  let(:manual_banner) { described_class.new(actionable: nil) }
  let(:offline_license?) { true }

  before do
    create_current_license({ cloud_licensing_enabled: true, offline_cloud_licensing_enabled: offline_license? })
  end

  describe '#display?' do
    subject(:display?) { manual_banner.display? }

    let(:should_check_namespace_plan?) { false } # indicates a self-managed instance
    let(:feature_flag_enabled) { true }

    before do
      allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?) { should_check_namespace_plan? }

      stub_feature_flags(automated_email_provision: feature_flag_enabled)
    end

    context 'when on GitLab.com' do
      let(:should_check_namespace_plan?) { true }

      it { is_expected.to eq(false) }
    end

    context 'when feature flag :automated_email_provision is disabled' do
      let(:feature_flag_enabled) { false }

      it { is_expected.to eq(false) }
    end

    context 'when current license is not an offline cloud license' do
      let(:offline_license?) { false }

      it { is_expected.to eq(false) }
    end

    it { expect { display? }.to raise_error(NotImplementedError) }
  end

  describe '#subject' do
    subject(:banner_subject) { manual_banner.subject }

    before do
      allow(manual_banner).to receive(:display?).and_return(display)
    end

    context 'when banner should not be displayed' do
      let(:display) { false }

      it { is_expected.to eq(nil) }
    end

    context 'when banner should be displayed' do
      let(:display) { true }

      it { expect { banner_subject }.to raise_error(NotImplementedError) }
    end
  end

  describe '#body' do
    subject(:banner_body) { manual_banner.body }

    before do
      allow(manual_banner).to receive(:display?).and_return(display)
    end

    context 'when banner should not be displayed' do
      let(:display) { false }

      it { is_expected.to eq(nil) }
    end

    context 'when banner should be displayed' do
      let(:display) { true }

      it { expect { banner_body }.to raise_error(NotImplementedError) }
    end
  end

  describe 'display_error_version?' do
    it { expect { manual_banner.display_error_version? }.to raise_error(NotImplementedError) }
  end
end
