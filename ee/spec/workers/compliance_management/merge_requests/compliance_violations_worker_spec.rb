# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplianceManagement::MergeRequests::ComplianceViolationsWorker, feature_category: :compliance_management do
  let(:worker) { described_class.new }
  let_it_be(:merge_request) { create(:merge_request, :merged) }

  let(:compliance_violations_service) { instance_spy(ComplianceManagement::MergeRequests::CreateComplianceViolationsService) }
  let(:job_args) { [merge_request] }

  include_examples 'an idempotent worker'

  describe "#perform" do
    before do
      allow(ComplianceManagement::MergeRequests::CreateComplianceViolationsService).to receive(:new).and_return(compliance_violations_service)
    end

    context 'if the merge request does not exist' do
      it 'does not call the service' do
        worker.perform(non_existing_record_id)

        expect(ComplianceManagement::MergeRequests::CreateComplianceViolationsService).not_to have_received(:new)
      end
    end

    context 'if the merge request exists' do
      it 'calls the service' do
        worker.perform(merge_request.id)

        expect(ComplianceManagement::MergeRequests::CreateComplianceViolationsService).to have_received(:new).with(merge_request)
      end
    end
  end
end
