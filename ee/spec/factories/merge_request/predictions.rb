# frozen_string_literal: true

FactoryBot.define do
  factory :predictions, class: 'MergeRequest::Predictions' do
    merge_request
    suggested_reviewers { { reviewers: [generate(:username)] } }
  end
end
