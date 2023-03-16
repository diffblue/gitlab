# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::IncidentSlaExceededCheckWorker, feature_category: :incident_management do
  let(:worker) { described_class.new }

  describe '#perform' do
    subject(:perform) { worker.perform }

    let_it_be(:label_applied_incident_sla) { create(:issuable_sla, :exceeded, :label_applied) }
    let_it_be(:exceeded_incident_sla) { create(:issuable_sla, :exceeded) }

    it 'calls the apply incident sla label service where the label is not applied already' do
      expect(IncidentManagement::ApplyIncidentSlaExceededLabelWorker)
        .to receive(:perform_async)
        .with(exceeded_incident_sla.issue_id)

      perform
    end
  end
end
