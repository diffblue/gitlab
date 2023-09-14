# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DraftNotes::PublishService, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:project) { merge_request.target_project }

  def publish
    DraftNotes::PublishService.new(merge_request, user).execute
  end

  before_all do
    project.add_maintainer(user)
  end

  shared_examples 'does not execute Llm::SummarizeSubmittedReviewService' do
    specify do
      expect(Llm::SummarizeSubmittedReviewService).not_to receive(:new)

      expect(publish[:status]).to eq(:success)
    end
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

    context 'when review author is the merge request author' do
      let_it_be(:user) { merge_request.author }

      it_behaves_like 'does not execute Llm::SummarizeSubmittedReviewService'
    end
  end

  context 'when the review has only 1 note' do
    before do
      create(:draft_note_on_text_diff, merge_request: merge_request, author: user)
    end

    it_behaves_like 'does not execute Llm::SummarizeSubmittedReviewService'
  end
end
