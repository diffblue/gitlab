# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DraftNotes::PublishService, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.target_project }
  let(:user) { merge_request.author }

  def publish
    DraftNotes::PublishService.new(merge_request, user).execute
  end

  context 'when the review has more than 1 note' do
    before do
      create(:draft_note_on_text_diff, merge_request: merge_request, author: user)
      create(:draft_note_on_text_diff, merge_request: merge_request, author: user)
    end

    it 'executes Llm::SummarizeSubmittedReviewService and returns success' do
      expect_next_instance_of(
        Llm::SummarizeSubmittedReviewService,
        user,
        merge_request,
        review_id: kind_of(Numeric),
        diff_id: merge_request.latest_merge_request_diff_id
      ) do |svc|
        expect(svc).to receive(:execute)
      end

      expect(publish[:status]).to eq(:success)
    end
  end

  context 'when the review has only 1 note' do
    before do
      create(:draft_note_on_text_diff, merge_request: merge_request, author: user)
    end

    it 'does not execute Llm::SummarizeSubmittedReviewService' do
      expect(Llm::SummarizeSubmittedReviewService).not_to receive(:new)

      expect(publish[:status]).to eq(:success)
    end
  end
end
