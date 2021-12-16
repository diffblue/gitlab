# frozen_string_literal: true

FactoryBot.define do
  factory :compliance_violation, class: 'MergeRequests::ComplianceViolation' do
    violating_user factory: :user
    merge_request

    trait :approved_by_merge_request_author do
      reason { :approved_by_merge_request_author }
    end

    trait :approved_by_committer do
      reason { :approved_by_committer }
    end

    trait :approved_by_insufficient_users do
      reason { :approved_by_insufficient_users }
    end
  end
end
