# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Review, feature_category: :code_review_workflow do
  describe 'associations' do
    it { is_expected.to have_one(:merge_request_review_llm_summary).class_name('MergeRequest::ReviewLlmSummary') }
  end
end
