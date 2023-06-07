# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::GeneratePolicyViolationCommentWorker, feature_category: :security_policy_management do
  include AfterNextHelpers

  describe '#perform' do
    let_it_be(:project) { create(:project) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project) }

    subject(:worker) { described_class.new }

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [merge_request.id, true] }
    end

    describe '#perform' do
      it 'calls Security::ScanResultPolicies::GeneratePolicyViolationCommentService#execute' do
        expect_next(Security::ScanResultPolicies::GeneratePolicyViolationCommentService, merge_request, true)
          .to receive(:execute).and_return(ServiceResponse.success)

        worker.perform(merge_request.id, true)
      end

      context 'when feature flag "security_policy_approval_notification" is disabled' do
        before do
          stub_feature_flags(security_policy_approval_notification: false)
        end

        it 'does nothing' do
          expect(Security::ScanResultPolicies::GeneratePolicyViolationCommentService).not_to receive(:new)

          worker.perform(merge_request.id, true)
        end
      end

      context 'with a non-existing merge request' do
        it 'does nothing' do
          expect(Security::ScanResultPolicies::GeneratePolicyViolationCommentService).not_to receive(:new)

          worker.perform(non_existing_record_id, true)
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
            'violated_policy' => true,
            'message' => 'error1, error2'
          ))

          worker.perform(merge_request.id, true)
        end
      end
    end
  end
end
