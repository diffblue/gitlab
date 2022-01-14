# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::PendingEscalations::Issue do
  let_it_be(:pending_escalation) { create(:incident_management_pending_issue_escalation) }

  describe '.class_for_check_worker' do
    subject { described_class.class_for_check_worker }

    it { is_expected.to eq(::IncidentManagement::PendingEscalations::IssueCheckWorker) }
  end

  describe '#escalatable' do
    let_it_be(:escalatable) { create(:incident_management_issuable_escalation_status, issue: pending_escalation.issue) }

    subject { pending_escalation.escalatable }

    it { is_expected.to eq(escalatable) }
  end

  describe '#type' do
    subject { pending_escalation.type }

    it { is_expected.to eq(:incident) }
  end

  context 'shared pending escalation features' do
    include_examples 'IncidentManagement::PendingEscalation model'
  end
end
