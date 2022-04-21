# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Findings::DeleteByJobIdWorker do
  let(:job_ids) { [1, 2, 3] }
  let(:event) { Ci::JobArtifactsDeletedEvent.new(data: { job_ids: job_ids }) }

  subject { consume_event(subscriber: described_class, event: event) }

  before do
    allow(::Security::Findings::CleanupService).to receive(:delete_by_build_ids)
  end

  it_behaves_like 'subscribes to event'

  it 'initiates the cleanup by build ids' do
    subject

    expect(::Security::Findings::CleanupService).to have_received(:delete_by_build_ids).with(job_ids)
  end
end
