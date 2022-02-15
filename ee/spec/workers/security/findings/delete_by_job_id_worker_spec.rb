# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Findings::DeleteByJobIdWorker do
  let_it_be(:security_scan1) { create(:security_scan) }
  let_it_be(:security_scan2) { create(:security_scan) }
  let_it_be(:security_finding_to_be_deleted) { create(:security_finding, scan: security_scan1) }
  let_it_be(:security_finding_not_to_be_deleted) { create(:security_finding, scan: security_scan2) }

  let(:event) { Ci::PipelineCreatedEvent.new(data: { job_ids: [security_scan1.build_id] }) }

  subject { consume_event(event) }

  def consume_event(event)
    described_class.new.perform(event.class.name, event.data)
  end

  it 'destroys all expired artifacts' do
    expect { subject }.to change { Security::Finding.count }.from(2).to(1)
  end
end
