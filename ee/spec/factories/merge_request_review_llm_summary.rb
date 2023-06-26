# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request_review_llm_summary, class: 'MergeRequest::ReviewLlmSummary' do
    association :user, factory: :user
    association :merge_request_diff, factory: :merge_request_diff
    review { association :review, merge_request: merge_request_diff.merge_request }
    provider { 0 }
    content { FFaker::Lorem.sentence }
  end
end
