# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::PendingEscalations::Alert do
  subject { create(:incident_management_pending_alert_escalation) }

  it { is_expected.to be_valid }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:process_at) }
    it { is_expected.to delegate_method(:project).to(:alert) }
    it { is_expected.to validate_uniqueness_of(:rule_id).scoped_to([:alert_id]) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:alert) }
    it { is_expected.to belong_to(:rule) }
  end

  describe 'scopes' do
    describe '.processable' do
      subject { described_class.processable }

      let_it_be(:policy) { create(:incident_management_escalation_policy) }
      let_it_be(:rule) { policy.rules.first }

      let_it_be(:two_months_ago_escalation) { create(:incident_management_pending_alert_escalation, rule: rule, process_at: 2.months.ago) }
      let_it_be(:three_weeks_ago_escalation) { create(:incident_management_pending_alert_escalation, rule: rule, process_at: 3.weeks.ago) }
      let_it_be(:three_days_ago_escalation) { create(:incident_management_pending_alert_escalation, rule: rule, process_at: 3.days.ago) }
      let_it_be(:future_escalation) { create(:incident_management_pending_alert_escalation, rule: rule, process_at: 5.minutes.from_now) }

      it { is_expected.to eq [three_weeks_ago_escalation, three_days_ago_escalation] }
    end
  end
end
