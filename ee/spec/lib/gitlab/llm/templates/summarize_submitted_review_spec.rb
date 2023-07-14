# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Templates::SummarizeSubmittedReview, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let_it_be(:review) { create(:review, merge_request: merge_request, author: merge_request.author) }
  let_it_be(:note_1) { create(:note_on_merge_request, project: project, noteable: merge_request, review: review) }
  let_it_be(:note_2) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, review: review) }

  subject { described_class.new(review) }

  describe '#to_prompt' do
    it 'includes lines per note' do
      prompt = subject.to_prompt

      expect(prompt).to include("Comment: #{note_1.note}")
      expect(prompt).to include("Comment: #{note_2.note}")
    end
  end
end
