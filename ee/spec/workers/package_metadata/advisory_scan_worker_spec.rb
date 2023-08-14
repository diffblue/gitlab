# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::AdvisoryScanWorker, feature_category: :software_composition_analysis do
  let_it_be(:advisory) { create(:pm_advisory) }
  let(:event) { PackageMetadata::IngestedAdvisoryEvent.new(data: { advisory_id: advisory.id }) }

  before do
    allow(PackageMetadata::AdvisoryScanService).to receive(:execute)
  end

  it_behaves_like 'subscribes to event'

  context 'when advisory exists' do
    it 'calls the advisory scanning service with the instantiated advisory' do
      consume_event(subscriber: described_class, event: event)
      expect(PackageMetadata::AdvisoryScanService).to have_received(:execute).with(advisory)
    end
  end

  context 'when advisory could not be found' do
    before do
      allow(PackageMetadata::Advisory).to receive(:find_by_id)
      .with(event.data[:advisory_id]).and_return(nil)
    end

    it 'logs the error and does not initiate a scan' do
      expect(Sidekiq.logger).to receive(:info).with(hash_including({ 'message' => 'Advisory not found.',
'advisory_id' => advisory.id }))

      consume_event(subscriber: described_class, event: event)
      expect(PackageMetadata::AdvisoryScanService).not_to have_received(:execute)
    end
  end
end
