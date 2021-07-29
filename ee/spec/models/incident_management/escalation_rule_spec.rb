# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::EscalationRule do
  let_it_be(:policy) { create(:incident_management_escalation_policy) }

  subject { build(:incident_management_escalation_rule, policy: policy) }

  it { is_expected.to be_valid }

  describe 'associations' do
    it { is_expected.to belong_to(:policy) }
    it { is_expected.to belong_to(:oncall_schedule) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:elapsed_time_seconds) }
    it { is_expected.to validate_numericality_of(:elapsed_time_seconds).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(24.hours) }
    it { is_expected.to validate_uniqueness_of(:policy_id).scoped_to([:oncall_schedule_id, :status, :elapsed_time_seconds] ).with_message('must have a unique schedule, status, and elapsed time') }
  end

  describe 'scopes' do
    let_it_be(:rule) { policy.rules.first }
    let_it_be(:removed_rule) { create(:incident_management_escalation_rule, :removed, policy: policy) }

    describe '.not_removed' do
      subject { described_class.not_removed }

      it { is_expected.to contain_exactly(rule) }
    end

    describe '.removed' do
      subject { described_class.removed }

      it { is_expected.to contain_exactly(removed_rule) }
    end
  end
end
