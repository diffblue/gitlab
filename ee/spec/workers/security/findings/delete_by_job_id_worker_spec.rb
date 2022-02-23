# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Findings::DeleteByJobIdWorker do
  let(:job_ids) { [1, 2, 3] }
  let(:event) { Ci::PipelineCreatedEvent.new(data: { job_ids: job_ids }) }

  subject(:consume_event) { described_class.new.perform(event.class.name, event.data) }

  before do
    allow(::Security::Findings::CleanupService).to receive(:delete_by_build_ids)
  end

  it 'initiates the cleanup by build ids' do
    consume_event

    expect(::Security::Findings::CleanupService).to have_received(:delete_by_build_ids).with(job_ids)
  end
end
