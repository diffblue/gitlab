# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::PendingEscalations::IssueCheckWorker, feature_category: :incident_management do
  let(:worker) { described_class.new }

  let_it_be(:escalation) { create(:incident_management_pending_issue_escalation) }

  describe '#perform' do
    subject { worker.perform(*args) }

    context 'with valid escalation' do
      let(:args) { [escalation.id.to_s] }

      it 'processes the escalation' do
        expect_next_instance_of(IncidentManagement::PendingEscalations::ProcessService, escalation) do |service|
          expect(service).to receive(:execute)
        end

        subject
      end
    end

    context 'without valid escalation' do
      let(:args) { [non_existing_record_id] }

      it 'does nothing' do
        expect(IncidentManagement::PendingEscalations::CreateService).not_to receive(:new)
        expect { subject }.not_to raise_error
      end
    end
  end
end
