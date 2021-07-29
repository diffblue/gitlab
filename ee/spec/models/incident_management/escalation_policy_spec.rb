# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::EscalationPolicy do
  subject { build(:incident_management_escalation_policy) }

  it { is_expected.to be_valid }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:rules) }
    it { is_expected.to have_many(:active_rules).order(elapsed_time_seconds: :asc, status: :asc).class_name('EscalationRule').inverse_of(:policy) }

    describe '.active_rules' do
      let(:policy) { create(:incident_management_escalation_policy) }
      let(:rule) { policy.rules.first }
      let(:removed_rule) { create(:incident_management_escalation_rule, :removed, policy: policy) }

      subject { policy.reload.active_rules }

      it { is_expected.to contain_exactly(rule) }
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:rules) }
    it { is_expected.to validate_uniqueness_of(:project_id).with_message(/can only have one escalation policy/).on(:create) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:project_id) }
    it { is_expected.to validate_length_of(:name).is_at_most(72) }
    it { is_expected.to validate_length_of(:description).is_at_most(160) }
  end
end
