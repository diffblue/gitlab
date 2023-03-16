# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::PendingEscalations::IssueCreateWorker, feature_category: :incident_management do
  let(:worker) { described_class.new }

  let_it_be(:escalation_status) { create(:incident_management_issuable_escalation_status) }
  let_it_be(:issue) { escalation_status.issue }

  describe '#perform' do
    subject { worker.perform(*args) }

    context 'with valid issue' do
      let(:args) { [issue.id.to_s] }

      it 'processes the escalation' do
        expect_next_instance_of(IncidentManagement::PendingEscalations::CreateService, escalation_status) do |service|
          expect(service).to receive(:execute)
        end

        subject
      end
    end

    context 'without valid issue' do
      let(:args) { [non_existing_record_id] }

      it 'does nothing' do
        expect(IncidentManagement::PendingEscalations::CreateService).not_to receive(:new)
        expect { subject }.not_to raise_error
      end
    end
  end
end
