# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::FetchSuggestedReviewersWorker, feature_category: :code_review_workflow do
  include AfterNextHelpers

  let_it_be(:merge_request) { create(:merge_request) }

  subject { described_class.new }

  describe '#perform' do
    context 'when merge request is not found' do
      it 'returns without calling the fetch suggested reviewer service' do
        expect(MergeRequests::FetchSuggestedReviewersService).not_to receive(:new)

        subject.perform(non_existing_record_id)
      end
    end

    context 'when merge request does not have changes' do
      let_it_be(:merge_request) { create(:merge_request, :without_diffs) }

      it 'returns without calling the fetch suggested reviewer service' do
        expect(MergeRequests::FetchSuggestedReviewersService).not_to receive(:new)

        subject.perform(merge_request.id)
      end
    end

    context 'when merge request is found' do
      let(:example_model_result) do
        {
          version: '0.1.0',
          top_n: 1,
          reviewers: ['root']
        }
      end

      let(:example_success_result) do
        example_model_result.merge({ status: :success })
      end

      let(:example_error_result) do
        example_model_result.merge({ status: :error })
      end

      context 'with a happy path' do
        it 'attempts to fetch suggested reviewers' do
          expect_next_instance_of(::MergeRequests::FetchSuggestedReviewersService) do |instance|
            expect(instance).to receive(:execute)
          end

          subject.perform(merge_request.id)
        end

        it 'updates the merge request with a successful result' do
          allow_next_instance_of(::MergeRequests::FetchSuggestedReviewersService) do |instance|
            allow(instance).to receive(:execute).and_return(example_success_result)
          end

          subject.perform(merge_request.id)

          expect(merge_request.predictions.suggested_reviewers).to eq(example_model_result.stringify_keys)
        end
      end

      context 'when issues occur' do
        let_it_be(:merge_request2) { create(:merge_request) }

        let(:logger) { subject.send(:logger) }

        it 'with an error result does not update the merge request predictions', :aggregate_failures do
          allow_next_instance_of(::MergeRequests::FetchSuggestedReviewersService) do |instance|
            allow(instance).to receive(:execute).and_return(example_error_result)
          end

          log_params = {
            result: {
              reviewers: ["root"],
              status: :error,
              top_n: 1,
              version: "0.1.0"
            }
          }
          expect(logger).to receive(:error).with(hash_including(log_params.stringify_keys)).and_call_original

          subject.perform(merge_request2.id)

          expect(merge_request2.predictions&.suggested_reviewers).to be_nil
        end
      end

      context 'when exceptions are raised' do
        it 're-raises exception when it is retriable' do
          allow_next(::MergeRequests::FetchSuggestedReviewersService)
            .to receive(:execute)
            .and_raise(Gitlab::AppliedMl::Errors::ConnectionFailed)

          expect { subject.perform(merge_request.id) }.to raise_error(Gitlab::AppliedMl::Errors::ConnectionFailed)
        end

        it 'does not raise but logs exception when it is swallowable', :aggregate_failures do
          allow_next(::MergeRequests::FetchSuggestedReviewersService)
            .to receive(:execute)
            .and_raise(Gitlab::AppliedMl::Errors::ResourceNotAvailable)

          expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
            Gitlab::AppliedMl::Errors::ResourceNotAvailable,
            project_id: merge_request.project.id,
            merge_request_id: merge_request.id
          )

          expect { subject.perform(merge_request.id) }.not_to raise_error
        end
      end
    end
  end
end
