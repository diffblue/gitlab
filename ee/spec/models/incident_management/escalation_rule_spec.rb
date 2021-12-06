# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::EscalationRule do
  subject { build(:incident_management_escalation_rule) }

  describe 'associations' do
    it { is_expected.to belong_to(:policy) }
    it { is_expected.to belong_to(:oncall_schedule).optional }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to have_one(:project).through(:policy) }
  end

  describe 'validations' do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:elapsed_time_seconds) }
    it { is_expected.to validate_numericality_of(:elapsed_time_seconds).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(24.hours) }
    it { is_expected.to validate_uniqueness_of(:oncall_schedule_id).scoped_to([:policy_id, :status, :elapsed_time_seconds] ).with_message('must be unique by status and elapsed time within a policy') }

    context 'user-based rules' do
      subject { build(:incident_management_escalation_rule, :with_user) }

      it { is_expected.to be_valid }
      it { is_expected.to validate_uniqueness_of(:user_id).scoped_to([:policy_id, :status, :elapsed_time_seconds] ).with_message('must be unique by status and elapsed time within a policy') }
    end

    context 'mutually exclusive attributes' do
      context 'when user and schedule are both provided' do
        let_it_be(:schedule) { create(:incident_management_oncall_schedule) }

        subject { build(:incident_management_escalation_rule, :with_user, oncall_schedule: schedule) }

        specify do
          expect(subject).to be_invalid
          expect(subject.errors.messages[:base]).to eq(['must have either an on-call schedule or user'])
        end
      end

      context 'neither user nor schedule are provided' do
        subject { build(:incident_management_escalation_rule, oncall_schedule: nil) }

        specify do
          expect(subject).to be_invalid
          expect(subject.errors.messages[:base]).to eq(['must have either an on-call schedule or user'])
        end
      end
    end
  end

  describe 'scopes' do
    let_it_be(:rule) { create(:incident_management_escalation_rule) }
    let_it_be(:removed_rule) { create(:incident_management_escalation_rule, :removed, policy: rule.policy) }
    let_it_be(:other_project_rule) { create(:incident_management_escalation_rule) }

    describe '.not_removed' do
      subject { described_class.not_removed }

      it { is_expected.to contain_exactly(rule, other_project_rule) }
    end

    describe '.removed' do
      subject { described_class.removed }

      it { is_expected.to contain_exactly(removed_rule) }
    end

    describe '.for_project' do
      let(:project) { other_project_rule.project }

      subject { described_class.for_project(project) }

      it { is_expected.to contain_exactly(other_project_rule) }
    end
  end
end
