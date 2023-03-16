# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CodeReviewMetricsWorker, feature_category: :value_stream_management do
  subject(:worker) { described_class.new }

  describe "#perform" do
    let(:operation) { '::Analytics::RefreshApprovalsData' }
    let(:merge_request) { create(:merge_request) }

    context 'with code review analytics feature available' do
      before do
        stub_licensed_features(code_review_analytics: true)
      end

      it 'executes operation for provided MR' do
        expect_next_instance_of(operation.constantize, merge_request) do |instance|
          expect(instance).to receive(:execute).with(force: true)
        end

        worker.perform(operation, merge_request.id, force: true)
      end

      context 'for invalid MR id' do
        it 'does not  execute  operation' do
          expect(operation.constantize).not_to receive(:new)

          worker.perform(operation, 1992291)
        end
      end

      context 'for invalid operation' do
        let(:operation) { 'SomeInvalidClassName' }

        it 'raises an error' do
          expect do
            worker.perform(operation, merge_request.id)
          end.to raise_error NameError, 'uninitialized constant SomeInvalidClassName'
        end
      end
    end
  end
end
