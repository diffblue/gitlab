# frozen_string_literal: true

RSpec.shared_examples 'creates an escalation' do
  specify do
    expect(IncidentManagement::PendingEscalations::AlertCreateWorker)
      .to receive(:perform_async)
      .with(a_kind_of(Integer))

    subject
  end
end

RSpec.shared_examples "deletes the target's escalations" do
  specify do
    before_count = target.pending_escalations.count
    expect(before_count).to be > 0
    expect { subject }.to change { target.pending_escalations.reload.count }.from(before_count).to(0)
  end
end

RSpec.shared_examples 'does not create or delete any escalations' do
  specify do
    expect(::IncidentManagement::PendingEscalations::AlertCreateWorker).not_to receive(:perform_async)

    expect { subject }
      .to not_change(::IncidentManagement::PendingEscalations::Alert, :count)
      .and not_change(::IncidentManagement::PendingEscalations::Issue, :count)
  end
end
