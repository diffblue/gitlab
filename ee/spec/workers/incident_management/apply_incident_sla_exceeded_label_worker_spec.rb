# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::ApplyIncidentSlaExceededLabelWorker, feature_category: :incident_management do
  let(:worker) { described_class.new }

  let_it_be_with_refind(:incident) { create(:incident, :with_sla) }
  let_it_be(:project) { incident.project }
  let_it_be(:label) do
    ::IncidentManagement::CreateIncidentSlaExceededLabelService
      .new(project)
      .execute
      .payload[:label]
  end

  subject(:perform) { worker.perform(incident.id) }

  before do
    stub_licensed_features(incident_sla: true)
  end

  context 'label exists already' do
    before do
      incident.labels << label
    end

    it 'does not add a label', :aggregate_failures do
      expect { subject }.not_to change { incident.labels.reload.count }
      expect(incident.labels.reload).to include(label)
    end
  end

  it 'adds a label to the incident', :aggregate_failures do
    expect { perform }.to change { incident.labels.reload.count }.by(1)
    expect(incident.labels.reload).to include(label)
  end

  it 'sets the label applied boolean' do
    expect { perform }.to change { incident.issuable_sla.reload.label_applied }.from(false).to(true)
  end

  it 'adds a note that the label was added', :aggregate_failures do
    expect { subject }.to change { incident.resource_label_events.reload.count }

    event = incident.resource_label_events.first
    expect(event.action).to eq('add')
    expect(event.label).to eq(label)
  end

  context 'label is already added' do
    before do
      incident.labels << label
    end

    it 'does not add a label', :aggregate_failures do
      expect { subject }.not_to change { incident.labels.reload.count }
      expect(incident.labels.reload).to contain_exactly(label)
    end

    it 'sets the label applied boolean' do
      expect { perform }.to change { incident.issuable_sla.reload.label_applied }.from(false).to(true)
    end
  end

  context 'for plain issues' do
    before_all do
      incident.update!(work_item_type: WorkItems::Type.default_by_type(:issue))
    end

    it 'does not add a label', :aggregate_failures do
      expect { subject }.not_to change { incident.labels.reload.count }
      expect(incident.labels.reload).to be_empty
    end
  end

  context 'without license' do
    before do
      stub_licensed_features(incident_sla: false)
    end

    it 'does not add a label', :aggregate_failures do
      expect { subject }.not_to change { incident.labels.reload.count }
      expect(incident.labels.reload).to be_empty
    end
  end
end
