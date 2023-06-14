# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::GeneratePolicyViolationCommentWorker, feature_category: :security_policy_management do
  include AfterNextHelpers

  describe '#perform' do
    let_it_be(:project) { create(:project) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project) }
    let_it_be(:violated_policy) { true }
    let_it_be(:report_type) do
      Security::ScanResultPolicies::PolicyViolationComment::REPORT_TYPES[:scan_finding]
    end

    let_it_be(:params) { { 'report_type' => report_type, 'violated_policy' => violated_policy } }

    subject(:worker) { described_class.new }

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [merge_request.id, params] }
    end

    it 'calls Security::ScanResultPolicies::GeneratePolicyViolationCommentService#execute' do
      expect_next(Security::ScanResultPolicies::GeneratePolicyViolationCommentService, merge_request,
        report_type, violated_policy)
        .to receive(:execute).and_return(ServiceResponse.success)

      worker.perform(merge_request.id, params)
    end

    context 'when feature flag "security_policy_approval_notification" is disabled' do
      before do
        stub_feature_flags(security_policy_approval_notification: false)
      end

      it 'does nothing' do
        expect(Security::ScanResultPolicies::GeneratePolicyViolationCommentService).not_to receive(:new)

        worker.perform(merge_request.id, params)
      end
    end

    context 'with a non-existing merge request' do
      it 'does nothing' do
        expect(Security::ScanResultPolicies::GeneratePolicyViolationCommentService).not_to receive(:new)

        worker.perform(non_existing_record_id, params)
      end
    end

    context 'when the service returns an error' do
      before do
        allow_next_instance_of(Security::ScanResultPolicies::GeneratePolicyViolationCommentService) do |service|
          allow(service).to receive(:execute).and_return(ServiceResponse.error(message: %w[error1 error2]))
        end
      end

      it 'logs the error' do
        expect(Sidekiq.logger).to receive(:warn).with(hash_including(
          'class' => 'Security::GeneratePolicyViolationCommentWorker',
          'merge_request_id' => merge_request.id,
          'report_type' => report_type,
          'violated_policy' => violated_policy,
          'message' => 'error1, error2'
        ))

        worker.perform(merge_request.id, params)
      end
    end
  end
end
