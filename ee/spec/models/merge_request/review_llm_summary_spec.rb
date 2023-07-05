# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::MergeRequest::ReviewLlmSummary, feature_category: :code_review_workflow do
  subject(:merge_request_review_llm_summary) { build(:merge_request_review_llm_summary) }

  describe 'associations' do
    it { is_expected.to belong_to(:merge_request_diff) }
    it { is_expected.to belong_to(:review) }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to validate_presence_of(:content) }
    it { is_expected.to validate_length_of(:content).is_at_most(2056) }
    it { is_expected.to validate_presence_of(:provider) }
  end

  describe '#reviewer' do
    it 'returns author of associated review' do
      expect(merge_request_review_llm_summary.reviewer).to eq(merge_request_review_llm_summary.review.author)
    end
  end
end
