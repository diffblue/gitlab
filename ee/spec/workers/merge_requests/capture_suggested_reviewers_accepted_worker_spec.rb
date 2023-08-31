# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::CaptureSuggestedReviewersAcceptedWorker, feature_category: :code_review_workflow do
  let_it_be(:reviewers) { create_list(:user, 3) }
  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:project) { merge_request.project }
  let_it_be(:predictions) do
    create(
      :predictions,
      merge_request: merge_request,
      suggested_reviewers: { reviewers: reviewers.map(&:username) }
    )
  end

  let(:reviewer_ids) { [reviewers.first(2).map(&:id)] }

  subject(:worker) { described_class.new }

  before_all do
    project.add_members(reviewers, :developer)
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [merge_request.id, reviewer_ids] }

    it 'updates the accepted reviewers' do
      allow(merge_request).to receive(:can_suggest_reviewers?).and_return(true)

      subject

      expect(predictions.reload.accepted_reviewer_usernames).to eq(reviewers.first(2).map(&:username))
    end
  end

  describe '#perform' do
    context 'when merge request is not found' do
      it 'returns without calling the capture suggested reviewer service' do
        expect(MergeRequests::CaptureSuggestedReviewersAcceptedService).not_to receive(:new)

        worker.perform(non_existing_record_id, reviewer_ids)
      end
    end

    context 'when merge request is found' do
      before do
        allow(MergeRequest).to receive(:find_by_id).and_return(merge_request)
      end

      context 'when merge request is not eligible' do
        before do
          allow(merge_request).to receive(:can_suggest_reviewers?).and_return(false)
        end

        it 'returns without calling the capture suggested reviewer service' do
          expect(MergeRequests::CaptureSuggestedReviewersAcceptedService).not_to receive(:new)

          worker.perform(merge_request.id, reviewer_ids)
        end
      end

      context 'when merge request is eligible' do
        before do
          allow(merge_request).to receive(:can_suggest_reviewers?).and_return(true)
        end

        context 'when reviewer ids is blank' do
          let(:reviewer_ids) { [] }

          it 'returns without calling the capture suggested reviewer service' do
            expect(MergeRequests::CaptureSuggestedReviewersAcceptedService).not_to receive(:new)

            worker.perform(merge_request.id, reviewer_ids)
          end
        end

        context 'when reviewer ids is not blank' do
          let(:reviewer_ids) { [1, 2] }

          context 'when service returns error' do
            let(:response) do
              ServiceResponse.error(message: 'an error has occurred')
            end

            it 'returns without logging extra metadata' do
              allow_next_instance_of(::MergeRequests::CaptureSuggestedReviewersAcceptedService) do |instance|
                allow(instance).to receive(:execute).with(merge_request, reviewer_ids).and_return(response)
              end

              expect(worker).not_to receive(:log_extra_metadata_on_done)

              worker.perform(merge_request.id, reviewer_ids)
            end
          end

          context 'when service returns success' do
            let(:response) do
              ServiceResponse.success(
                payload: {
                  project_id: merge_request.project.id,
                  merge_request_id: merge_request.id,
                  reviewers: %w[bob mary]
                }
              )
            end

            it 'attempts to capture suggested reviewers accepted' do
              expect_next_instance_of(::MergeRequests::CaptureSuggestedReviewersAcceptedService) do |instance|
                expect(instance).to receive(:execute).with(merge_request, reviewer_ids).and_return(response)
              end

              worker.perform(merge_request.id, reviewer_ids)
            end

            it 'logs with extra metadata', :aggregate_failures do
              allow_next_instance_of(::MergeRequests::CaptureSuggestedReviewersAcceptedService) do |instance|
                allow(instance).to receive(:execute).and_return(response)
              end

              expect(worker).to receive(:log_extra_metadata_on_done)
                .with(:project_id, response.payload[:project_id])
              expect(worker).to receive(:log_extra_metadata_on_done)
                .with(:merge_request_id, response.payload[:merge_request_id])
              expect(worker).to receive(:log_extra_metadata_on_done)
                .with(:reviewers, response.payload[:reviewers])

              worker.perform(merge_request.id, reviewer_ids)
            end
          end
        end
      end
    end
  end
end
