# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap do
  describe '.trimming_enabled?' do
    subject(:trimming_enabled?) { described_class.trimming_enabled? }

    context 'when free_user_cap_data_remediation_job is disabled' do
      before do
        stub_feature_flags(free_user_cap_data_remediation_job: false)
      end

      it { is_expected.to be false }
    end

    context 'when :free_user_cap_data_remediation_job is enabled' do
      before do
        stub_feature_flags(free_user_cap_data_remediation_job: true)
      end

      it { is_expected.to be true }
    end
  end

  describe '.group_sharing_remediation_enabled?' do
    subject(:trimming_enabled?) { described_class.group_sharing_remediation_enabled? }

    context 'when :free_user_cap_group_sharing_remediation is disabled' do
      before do
        stub_feature_flags(free_user_cap_group_sharing_remediation: false)
      end

      it { is_expected.to be false }
    end

    context 'when :free_user_cap_group_sharing_remediation is enabled' do
      before do
        stub_feature_flags(free_user_cap_group_sharing_remediation: true)
      end

      it { is_expected.to be true }
    end
  end
end
