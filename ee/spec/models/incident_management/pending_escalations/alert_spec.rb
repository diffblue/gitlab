# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::PendingEscalations::Alert do
  let(:pending_escalation) { build(:incident_management_pending_alert_escalation) }

  describe '.class_for_check_worker' do
    subject { described_class.class_for_check_worker }

    it { is_expected.to eq(::IncidentManagement::PendingEscalations::AlertCheckWorker) }
  end

  describe '#escalatable' do
    subject { pending_escalation.escalatable }

    it { is_expected.to eq(pending_escalation.alert) }
  end

  describe '#type' do
    subject { pending_escalation.type }

    it { is_expected.to eq(:alert) }
  end

  context 'shared pending escalation features' do
    include_examples 'IncidentManagement::PendingEscalation model'
  end
end
