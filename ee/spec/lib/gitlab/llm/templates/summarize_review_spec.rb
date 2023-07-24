# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Templates::SummarizeReview, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let_it_be(:draft_note_1) { create(:draft_note, merge_request: merge_request) }
  let_it_be(:draft_note_2) { create(:draft_note, merge_request: merge_request) }

  subject { described_class.new([draft_note_1, draft_note_2]) }

  describe '#to_prompt' do
    it 'includes lines per note' do
      prompt = subject.to_prompt

      expect(prompt).to include("Comment: #{draft_note_1.note}")
      expect(prompt).to include("Comment: #{draft_note_2.note}")
    end
  end
end
