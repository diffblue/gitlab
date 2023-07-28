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

  describe '.from_reviewer' do
    let(:review_1) { create(:review) }
    let(:review_2) { create(:review) }
    let!(:review_llm_summary_1) { create(:merge_request_review_llm_summary, review: review_1) }
    let!(:review_llm_summary_2) { create(:merge_request_review_llm_summary, review: review_2) }

    it 'returns review LLM summaries that were generated for the reviews from the reviewer' do
      expect(described_class.from_reviewer(review_1.author)).to eq([review_llm_summary_1])
    end
  end

  describe '#reviewer' do
    it 'returns author of associated review' do
      expect(merge_request_review_llm_summary.reviewer).to eq(merge_request_review_llm_summary.review.author)
    end
  end
end
