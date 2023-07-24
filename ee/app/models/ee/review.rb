# frozen_string_literal: true

module EE
  module Review
    extend ActiveSupport::Concern

    prepended do
      has_one :merge_request_review_llm_summary, class_name: 'MergeRequest::ReviewLlmSummary'
    end
  end
end
