# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScanResultPolicyRead, feature_category: :security_policy_management do
  describe 'associations' do
    it { is_expected.to belong_to(:security_orchestration_policy_configuration) }
  end

  describe 'validations' do
    let_it_be(:scan_result_policy_read) { create(:scan_result_policy_read) }

    subject { scan_result_policy_read }

    it { is_expected.not_to allow_value(nil).for(:match_on_inclusion) }
    it { is_expected.to allow_value(true, false).for(:match_on_inclusion) }

    it { is_expected.not_to allow_value(nil).for(:role_approvers) }
    it { is_expected.to(validate_inclusion_of(:role_approvers).in_array(Gitlab::Access.values)) }
  end

  describe '#newly_detected?' do
    subject { scan_result_policy_read.newly_detected? }

    context 'when license_states contains newly_detected' do
      let_it_be(:scan_result_policy_read) { create(:scan_result_policy_read, license_states: ['newly_detected']) }

      it { is_expected.to be_truthy }
    end

    context 'when license_states does not contain newly_detected' do
      let_it_be(:scan_result_policy_read) { create(:scan_result_policy_read, license_states: ['detected']) }

      it { is_expected.to be_falsey }
    end
  end
end
